import Foundation
import CryptoKit
import Testing
@testable import FocusSync

@Suite("Device identity and proofs (CONTRACT.md Device keys and proofs)")
struct DeviceIdentityTests {
    @Test func canonicalStringIsFourLinesWithTheBodyHash() {
        let body = Data(#"{"epoch":3}"#.utf8)
        let canonical = DeviceProof.canonicalString(method: "put", pathWithQuery: "/v1/keys/slots/abc?x=1", timestamp: "1790000000", body: body)
        #expect(canonical == "PUT\n/v1/keys/slots/abc?x=1\n1790000000\n\(Hex.encode(SHA256.hash(data: body)))")
        let empty = DeviceProof.canonicalString(method: "GET", pathWithQuery: "/v1/keys", timestamp: "1", body: nil)
        #expect(empty.hasSuffix("\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"))
        #expect(!empty.hasSuffix("\n\n"))
        #expect(empty.split(separator: "\n", omittingEmptySubsequences: false).count == 4)
    }

    @Test func proofHeadersVerifyWithThePublicKey() throws {
        let identity = Fixture.identity()
        let body = Data(#"{"confirm":"DELETE"}"#.utf8)
        let time = Date(timeIntervalSince1970: 1_790_000_000.9)
        let headers = try DeviceProof(identity: identity).sign(method: "DELETE", pathWithQuery: "/v1/account", body: body, timestamp: time)

        #expect(headers.deviceId == identity.deviceId.uuidString.lowercased())
        #expect(headers.timestamp == "1790000000")
        #expect(Set(headers.dictionary.keys) == ["X-Device-Id", "X-Device-Timestamp", "X-Device-Signature"])
        let raw = try #require(Base64URL.decode(headers.signature))
        #expect(raw.count == 64)
        #expect(!headers.signature.contains("="))

        // Verified the way the server does, with the registered public key.
        let publicKey = try P256.Signing.PublicKey(x963Representation: try #require(Base64URL.decode(identity.signingKey)))
        let canonical = DeviceProof.canonicalString(method: "DELETE", pathWithQuery: "/v1/account", timestamp: headers.timestamp, body: body)
        #expect(publicKey.isValidSignature(try P256.Signing.ECDSASignature(rawRepresentation: raw), for: Data(canonical.utf8)))
        #expect(DeviceProof.isValid(headers, method: "DELETE", pathWithQuery: "/v1/account", body: body, publicKey: publicKey))
        // Any change breaks it.
        #expect(!DeviceProof.isValid(headers, method: "DELETE", pathWithQuery: "/v1/account", body: Data("{}".utf8), publicKey: publicKey))
        #expect(!DeviceProof.isValid(headers, method: "DELETE", pathWithQuery: "/v1/devices/x", body: body, publicKey: publicKey))
        #expect(!DeviceProof.isValid(ProofHeaders(deviceId: headers.deviceId, timestamp: "1790000001", signature: headers.signature),
                                     method: "DELETE", pathWithQuery: "/v1/account", body: body, publicKey: publicKey))
    }

    @Test func identityIsMadeOnceAndReloaded() throws {
        let store = InMemorySecureStore()
        let first = try DeviceIdentity.loadOrCreate(in: store, preferSecureEnclave: false)
        let second = try DeviceIdentity.loadOrCreate(in: store, preferSecureEnclave: false)
        #expect(first.deviceId == second.deviceId)
        #expect(first.signingKey == second.signingKey)
        #expect(first.agreementKey == second.agreementKey)
        #expect(!first.usesSecureEnclave)
        #expect(try store.allKeys() == ["device.agreement", "device.id", "device.signing"])
        #expect(String(data: try #require(try store.data(for: "device.id")), encoding: .utf8) == first.deviceId.uuidString.lowercased())

        // Public keys are the 65-byte uncompressed points.
        let signing = try #require(Base64URL.decode(first.signingKey))
        #expect(signing.count == 65 && signing.first == 0x04)
        #expect(try #require(Base64URL.decode(first.agreementKey)).count == 65)

        // A proof from the reloaded identity verifies with the first one's key.
        let headers = try DeviceProof(identity: second).sign(method: "GET", pathWithQuery: "/v1/keys", body: nil, timestamp: Date())
        #expect(DeviceProof.isValid(headers, method: "GET", pathWithQuery: "/v1/keys", body: nil, publicKey: first.signingPublicKey))

        DeviceIdentity.removeStored(from: store)
        #expect(try store.allKeys().isEmpty)
    }

    @Test func secureEnclaveKeysSignWhenThisMachineHasOne() throws {
        // On a Mac or iPhone with a Secure Enclave the key lives there; elsewhere it falls back to software.
        let store = InMemorySecureStore()
        let identity = try DeviceIdentity.loadOrCreate(in: store, preferSecureEnclave: true)
        let reloaded = try DeviceIdentity.loadOrCreate(in: store, preferSecureEnclave: true)
        #expect(identity.usesSecureEnclave == reloaded.usesSecureEnclave)
        let headers = try DeviceProof(identity: reloaded).sign(method: "POST", pathWithQuery: "/v1/auth/refresh",
                                                              body: Data("{}".utf8), timestamp: Date())
        #expect(DeviceProof.isValid(headers, method: "POST", pathWithQuery: "/v1/auth/refresh", body: Data("{}".utf8),
                                    publicKey: identity.signingPublicKey))
    }

    @Test func registrationIsTheDeviceObject() throws {
        let identity = Fixture.identity(UUID(uuidString: "0199A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B")!)
        let device = identity.registration(appVersion: "1.2", osVersion: "26.0", model: "iPhone17,1")
        let json = try JSONSerialization.jsonObject(with: FocusJSON.encode(device)) as? [String: String]
        #expect(json == ["deviceId": "0199a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b", "model": "iPhone17,1", "osVersion": "26.0",
                         "appVersion": "1.2", "signingKey": identity.signingKey, "agreementKey": identity.agreementKey])
    }
}
