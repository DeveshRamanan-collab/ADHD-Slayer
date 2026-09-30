import Foundation
import CryptoKit
import Testing
@testable import FocusSync

/// Fixed-input vectors in `Fixtures/contract-vectors.json`, shared with the server (backend/api).
/// Regenerate with `FOCUS_WRITE_VECTORS=1 swift test --filter ContractVectorTests`; ECDSA and HPKE
/// outputs are random each time, so regenerating changes those values (they still verify).
@Suite("Contract vectors shared with the server")
struct ContractVectorTests {
    enum Input {
        static let signingKeyHex = "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
        static let agreementKeyHex = "519b423d715f8b581f4fa8ee59f4771a5b44c8130b4e3eacca54a56dda72b464"
        static let deviceId = UUID(uuidString: "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")!
        static let accountId = UUID(uuidString: "0199a1b2-0000-7000-8000-000000000001")!
        static let snapshotId = UUID(uuidString: "4f1c2d3e-5a6b-4c7d-8e9f-a0b1c2d3e4f5")!
        static let transferId = UUID(uuidString: "0199a1b2-1111-7222-8333-444455556666")!
        static let arkHex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
        static let dekHex = "202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f"
        static let dekNonceHex = "a0a1a2a3a4a5a6a7a8a9aaab"
        static let nonceHex = "b0b1b2b3b4b5b6b7b8b9babb"
        static let recoveryBytesHex = "0123456789abcdeffedcba98765432"
        static let recoveryNonceHex = "c0c1c2c3c4c5c6c7c8c9cacb"
        static let magicLinkKeyHex = String(repeating: "0b", count: 32)
        static let linkId = UUID(uuidString: "0199a1b2-5555-7666-8777-888899990000")!
        static let linkExpiresAtMs: UInt64 = 1_790_000_900_000
        static let linkSecretHex = String(repeating: "5a", count: 32)
        static let rawNonce = "kHf8Z0bH1-Q8dM9eA3nQvP0cY2uW5xR7tL4sJ6gE1aB"
        static let linkVerifier = "Yq3vW8xZ2bN5mK7jH4gF6dS1aP9oI0uT3rE5wQ7yU2c"
        static let createdAt = "2026-09-30T01:02:03.456Z"
        static let epoch = 3
        static let bundle = #"{"meta":{"createdAt":"2026-09-30T01:02:03.456Z","deviceId":"0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b","highestHLC":0,"schema":1},"tasks":[]}"#

        static let proofCases: [(method: String, path: String, timestamp: String, body: String?)] = [
            ("PUT", "/v1/keys/slots/0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b", "1790000000", #"{"ciphertext":"c2xvdA","enc":"ZW5j","epoch":3}"#),
            ("GET", "/v1/sync/batches?after=c%2F1%202&limit=100", "1790000123", nil),
            ("POST", "/v1/auth/refresh", "1790000456", #"{"refreshToken":"q3mXw0Z9h7yVb6nE2rT8kL1pS4dF5gH3jK6lZ8xC0vB"}"#),
            ("DELETE", "/v1/account", "1790000789", #"{"confirm":"DELETE"}"#),
        ]
    }

    static let url = fixtureURL("contract-vectors.json")

    // MARK: Checking

    @Test func vectorsMatchThisImplementation() throws {
        let data = try Data(contentsOf: Self.url)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Device proofs: canonical strings, body hashes, and signatures that verify with the fixed public key.
        let proofs = try #require(root["deviceProof"] as? [String: Any])
        let publicKeyText = try #require(proofs["signingPublicKey"] as? String)
        let publicKeyData = try #require(Base64URL.decode(publicKeyText))
        let publicKey = try P256.Signing.PublicKey(x963Representation: publicKeyData)
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: try #require(Hex.decode(Input.signingKeyHex)))
        #expect(privateKey.publicKey.x963Representation == publicKeyData)
        let cases = try #require(proofs["cases"] as? [[String: Any]])
        #expect(cases.count == Input.proofCases.count)
        for row in cases {
            let method = try #require(row["method"] as? String)
            let path = try #require(row["pathWithQuery"] as? String)
            let timestamp = try #require(row["timestamp"] as? String)
            let body = (row["body"] as? String).map { Data($0.utf8) }
            #expect(row["bodySha256Hex"] as? String == Hex.encode(SHA256.hash(data: body ?? Data())))
            #expect(row["canonical"] as? String == DeviceProof.canonicalString(method: method, pathWithQuery: path, timestamp: timestamp, body: body))
            let headers = try #require(row["headers"] as? [String: String])
            let proof = ProofHeaders(deviceId: try #require(headers["X-Device-Id"]), timestamp: try #require(headers["X-Device-Timestamp"]),
                                     signature: try #require(headers["X-Device-Signature"]))
            #expect(proof.deviceId == Input.deviceId.uuidString.lowercased())
            #expect(proof.timestamp == timestamp)
            #expect(DeviceProof.isValid(proof, method: method, pathWithQuery: path, body: body, publicKey: publicKey), "\(method) \(path)")
            #expect(!DeviceProof.isValid(proof, method: method, pathWithQuery: path + "x", body: body, publicKey: publicKey))
        }

        // Nonces and challenges.
        let nonces = try #require(root["signInNonces"] as? [[String: String]])
        for row in nonces { #expect(SignInNonce(raw: try #require(row["rawNonce"])).hashed == row["hashedHex"]) }
        let pkce = try #require(root["pkceS256"] as? [[String: String]])
        for row in pkce { #expect(PKCE.challenge(for: try #require(row["verifier"])) == row["challenge"]) }
        let link = try #require(root["emailLink"] as? [String: Any])
        #expect(EmailLinkVerifier(verifier: try #require(link["linkVerifier"] as? String)).challenge == link["linkChallenge"] as? String)

        // The link token layout and MAC.
        let token = try #require(link["token"] as? [String: Any])
        let rebuilt = Self.linkToken()
        #expect(token["token"] as? String == rebuilt.token)
        #expect(token["macHex"] as? String == rebuilt.macHex)
        let tokenText = try #require(token["token"] as? String)
        let parsed = try #require(EmailLink.Token(tokenText))
        #expect(parsed.id == Input.linkId)
        #expect(parsed.expiresAt == Date(timeIntervalSince1970: TimeInterval(Input.linkExpiresAtMs) / 1000))
        let urlText = try #require(token["url"] as? String)
        let linkURL = try #require(URL(string: urlText))
        #expect(EmailLink.token(from: linkURL) == rebuilt.token)

        // FCS1: the key hierarchy and header bytes are deterministic; the stored container opens.
        let snapshot = try #require(root["snapshot"] as? [String: Any])
        let ark = try AccountRootKey(epoch: Input.epoch, rawKey: try #require(Hex.decode(Input.arkHex)))
        #expect(snapshot["kekHex"] as? String == ark.keyEncryptionKey(accountId: Input.accountId).withUnsafeBytes { Hex.encode($0) })
        let resealed = try Self.sealSnapshot()
        #expect(snapshot["headerJson"] as? String == String(data: resealed.headerBytes, encoding: .utf8))
        #expect(snapshot["headerLength"] as? Int == resealed.headerBytes.count)
        #expect(snapshot["headerSha256Hex"] as? String == Hex.encode(resealed.aad))
        #expect(snapshot["wrappedDek"] as? String == resealed.header.wrappedDek)
        let containerText = try #require(snapshot["containerBase64"] as? String)
        let container = try #require(Data(base64Encoded: containerText))
        #expect(snapshot["sha256Base64Url"] as? String == Base64URL.encode(SHA256.hash(data: container)))
        #expect(snapshot["xAmzChecksumSha256"] as? String == Data(SHA256.hash(data: container)).base64EncodedString())
        #expect(container.bytes(at: 8, length: resealed.headerBytes.count) == resealed.headerBytes)
        let opened = try SnapshotContainer.open(container, accountId: Input.accountId) { $0 == Input.epoch ? ark : nil }
        #expect(String(data: opened.bundle, encoding: .utf8) == Input.bundle)

        // HPKE device slot opens with the fixed agreement key.
        let slotRow = try #require(root["deviceSlot"] as? [String: Any])
        let agreement = try P256.KeyAgreement.PrivateKey(rawRepresentation: try #require(Hex.decode(Input.agreementKeyHex)))
        #expect(slotRow["recipientPublicKey"] as? String == Base64URL.encode(agreement.publicKey.x963Representation))
        #expect(slotRow["info"] as? String == String(data: DeviceSlot.info(accountId: Input.accountId, epoch: Input.epoch), encoding: .utf8))
        let slot = SealedSlot(epoch: Input.epoch, enc: try #require(slotRow["enc"] as? String), ciphertext: try #require(slotRow["ciphertext"] as? String))
        #expect(try DeviceSlot.open(slot, with: agreement, accountId: Input.accountId) == ark)

        // Recovery key and slot.
        let recovery = try #require(root["recovery"] as? [String: Any])
        let recoveryKey = try RecoveryKey(bytes: try #require(Hex.decode(Input.recoveryBytesHex)))
        #expect(recovery["formatted"] as? String == recoveryKey.formatted)
        for typed in try #require(recovery["alsoAccepted"] as? [String]) { #expect(try RecoveryKey(parsing: typed) == recoveryKey, "\(typed)") }
        #expect(recovery["keyHex"] as? String == RecoverySlot.key(for: recoveryKey, accountId: Input.accountId).withUnsafeBytes { Hex.encode($0) })
        let recoverySlot = try RecoverySlot.seal(ark, with: recoveryKey, accountId: Input.accountId, nonce: try #require(Hex.decode(Input.recoveryNonceHex)))
        #expect(recovery["ciphertext"] as? String == recoverySlot.ciphertext)
        #expect(recovery["nonce"] as? String == recoverySlot.nonce)

        // Transfer fingerprint and QR payload.
        let transfer = try #require(root["transfer"] as? [String: Any])
        let fingerprint = KeyTransfer.fingerprint(of: agreement.publicKey)
        #expect(transfer["fingerprintHex"] as? String == Hex.encode(fingerprint))
        #expect(transfer["fingerprintDisplay"] as? String == KeyTransfer.displayFingerprint(fingerprint))
        #expect(transfer["qrPayload"] as? String == KeyTransfer.Code(transferId: Input.transferId, fingerprint: fingerprint).qrPayload)
    }

    // MARK: Writing

    @Test(.enabled(if: ProcessInfo.processInfo.environment["FOCUS_WRITE_VECTORS"] == "1"))
    func writeVectors() throws {
        let signingKey = try P256.Signing.PrivateKey(rawRepresentation: Hex.decode(Input.signingKeyHex)!)
        let agreement = try P256.KeyAgreement.PrivateKey(rawRepresentation: Hex.decode(Input.agreementKeyHex)!)
        let identity = DeviceIdentity(deviceId: Input.deviceId, signingKey: signingKey, agreementKey: agreement)
        let proof = DeviceProof(identity: identity)

        var cases: [[String: Any]] = []
        for item in Input.proofCases {
            let body = item.body.map { Data($0.utf8) }
            let headers = try proof.sign(method: item.method, pathWithQuery: item.path, body: body,
                                         timestamp: Date(timeIntervalSince1970: TimeInterval(item.timestamp)!))
            cases.append([
                "method": item.method, "pathWithQuery": item.path, "timestamp": item.timestamp, "body": item.body ?? NSNull(),
                "bodySha256Hex": Hex.encode(SHA256.hash(data: body ?? Data())),
                "canonical": DeviceProof.canonicalString(method: item.method, pathWithQuery: item.path, timestamp: item.timestamp, body: body),
                "headers": headers.dictionary,
            ])
        }

        let ark = try AccountRootKey(epoch: Input.epoch, rawKey: Hex.decode(Input.arkHex)!)
        let sealed = try Self.sealSnapshot()
        let compressed = try SnapshotContainer.compress(Data(Input.bundle.utf8))
        let slot = try DeviceSlot.seal(ark, to: agreement.publicKey, accountId: Input.accountId)
        let recoveryKey = try RecoveryKey(bytes: Hex.decode(Input.recoveryBytesHex)!)
        let recoverySlot = try RecoverySlot.seal(ark, with: recoveryKey, accountId: Input.accountId, nonce: Hex.decode(Input.recoveryNonceHex)!)
        let fingerprint = KeyTransfer.fingerprint(of: agreement.publicKey)
        let link = Self.linkToken()
        let formatted = recoveryKey.formatted

        let root: [String: Any] = [
            "about": "Fixed-input vectors for backend/CONTRACT.md, written by app/FocusCore/Tests/FocusSyncTests/ContractVectorTests.swift. "
                + "Binary is unpadded base64url unless a field name ends in Hex (lowercase hex) or Base64 (standard padded base64). "
                + "ECDSA signatures and HPKE outputs are random per run; they verify with the keys given.",
            "contractVersion": FocusSync.contractVersion,
            "deviceProof": [
                "deviceId": Input.deviceId.uuidString.lowercased(),
                "signingPrivateKeyHex": Input.signingKeyHex,
                "signingPublicKey": identity.signingKey,
                "note": "Canonical string: METHOD, path with query exactly as sent (including /v1), timestamp, lowercase hex SHA-256 of the body, joined by \\n with no trailing newline. X-Device-Signature is the raw 64-byte r||s (ieee-p1363) over the UTF-8 canonical string, base64url.",
                "cases": cases,
            ],
            "signInNonces": [["rawNonce": Input.rawNonce, "hashedHex": SignInNonce(raw: Input.rawNonce).hashed],
                             ["rawNonce": "abc", "hashedHex": SignInNonce(raw: "abc").hashed]],
            "pkceS256": [["verifier": "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk", "challenge": PKCE.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
                          "source": "RFC 7636 appendix B"]],
            "emailLink": [
                "linkVerifier": Input.linkVerifier,
                "linkChallenge": EmailLinkVerifier(verifier: Input.linkVerifier).challenge,
                "token": [
                    "magicLinkKeyHex": Input.magicLinkKeyHex,
                    "id": Input.linkId.uuidString.lowercased(),
                    "expiresAtMs": Input.linkExpiresAtMs,
                    "secretHex": Input.linkSecretHex,
                    "secretSha256Hex": Hex.encode(SHA256.hash(data: Hex.decode(Input.linkSecretHex)!)),
                    "macHex": link.macHex,
                    "token": link.token,
                    "url": "https://focus.adhdslayer.au/auth/email#t=\(link.token)",
                    "note": "token = base64url(id 16 bytes || expiresAt 8 bytes big-endian Unix ms || secret 32 || HMAC-SHA256(key, first 56 bytes)).",
                ] as [String: Any],
            ],
            "snapshot": [
                "accountId": Input.accountId.uuidString.lowercased(),
                "snapshotId": Input.snapshotId.uuidString.lowercased(),
                "deviceId": Input.deviceId.uuidString.lowercased(),
                "epoch": Input.epoch, "schema": 1, "createdAt": Input.createdAt,
                "arkHex": Input.arkHex,
                "kekHex": ark.keyEncryptionKey(accountId: Input.accountId).withUnsafeBytes { Hex.encode($0) },
                "kekDerivation": "HKDF-SHA256(ikm ARK, salt UTF-8 lowercase accountId, info focus.kek.v1, 32 bytes)",
                "dekHex": Input.dekHex, "dekNonceHex": Input.dekNonceHex, "nonceHex": Input.nonceHex,
                "dekAad": "focus.dek.v1:\(Input.snapshotId.uuidString.lowercased())",
                "wrappedDek": sealed.header.wrappedDek,
                "bundle": Input.bundle,
                "compressedLength": compressed.count,
                "paddedLength": sealed.header.paddedLength,
                "headerJson": String(data: sealed.headerBytes, encoding: .utf8)!,
                "headerLength": sealed.headerBytes.count,
                "headerSha256Hex": Hex.encode(sealed.aad),
                "payloadAad": "the 32 raw bytes of headerSha256Hex",
                "containerBase64": sealed.data.base64EncodedString(),
                "sha256Base64Url": sealed.sha256Base64URL,
                "xAmzChecksumSha256": sealed.sha256Base64,
            ] as [String: Any],
            "deviceSlot": [
                "accountId": Input.accountId.uuidString.lowercased(), "epoch": Input.epoch,
                "info": String(data: DeviceSlot.info(accountId: Input.accountId, epoch: Input.epoch), encoding: .utf8)!,
                "ciphersuite": "HPKE P256_SHA256_AES_GCM_256 (DHKEM P-256, HKDF-SHA256, AES-256-GCM), base mode, empty AAD",
                "recipientPrivateKeyHex": Input.agreementKeyHex,
                "recipientPublicKey": Base64URL.encode(agreement.publicKey.x963Representation),
                "arkHex": Input.arkHex, "enc": slot.enc, "ciphertext": slot.ciphertext,
            ] as [String: Any],
            "recovery": [
                "bytesHex": Input.recoveryBytesHex,
                "formatted": formatted,
                "alsoAccepted": [formatted.lowercased(), formatted.replacingOccurrences(of: "-", with: " "),
                                 formatted.replacingOccurrences(of: "-", with: "")],
                "keyHex": RecoverySlot.key(for: recoveryKey, accountId: Input.accountId).withUnsafeBytes { Hex.encode($0) },
                "aad": String(data: RecoverySlot.aad(accountId: Input.accountId, epoch: Input.epoch), encoding: .utf8)!,
                "epoch": Input.epoch, "arkHex": Input.arkHex,
                "nonce": recoverySlot.nonce, "ciphertext": recoverySlot.ciphertext,
            ] as [String: Any],
            "transfer": [
                "agreementPublicKey": Base64URL.encode(agreement.publicKey.x963Representation),
                "fingerprintHex": Hex.encode(fingerprint),
                "fingerprintDisplay": KeyTransfer.displayFingerprint(fingerprint),
                "fingerprintBase64Url": Base64URL.encode(fingerprint),
                "transferId": Input.transferId.uuidString.lowercased(),
                "qrPayload": KeyTransfer.Code(transferId: Input.transferId, fingerprint: fingerprint).qrPayload,
            ],
        ]
        let json = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try FileManager.default.createDirectory(at: Self.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (json + Data("\n".utf8)).write(to: Self.url)
    }

    // MARK: Shared

    static func sealSnapshot() throws -> SnapshotContainer.Sealed {
        let ark = try AccountRootKey(epoch: Input.epoch, rawKey: Hex.decode(Input.arkHex)!)
        return try SnapshotContainer.seal(bundle: Data(Input.bundle.utf8), with: ark, accountId: Input.accountId,
                                          snapshotId: Input.snapshotId, deviceId: Input.deviceId, schema: 1,
                                          createdAt: FocusJSON.date(from: Input.createdAt)!, dataKey: Hex.decode(Input.dekHex)!,
                                          dekNonce: Hex.decode(Input.dekNonceHex)!, nonce: Hex.decode(Input.nonceHex)!)
    }

    static func linkToken() -> (token: String, macHex: String) {
        var bytes = Data(Input.linkId.uuidBytes)
        bytes.append(contentsOf: (0..<8).reversed().map { UInt8(Input.linkExpiresAtMs >> (UInt64($0) * 8) & 0xFF) })
        bytes.append(Hex.decode(Input.linkSecretHex)!)
        let mac = Data(HMAC<SHA256>.authenticationCode(for: bytes, using: SymmetricKey(data: Hex.decode(Input.magicLinkKeyHex)!)))
        return (Base64URL.encode(bytes + mac), Hex.encode(mac))
    }
}
