import { createPublicKey, type KeyObject } from 'node:crypto';

/** DER SubjectPublicKeyInfo header for an uncompressed P-256 point; the 65 point bytes follow. */
const SPKI_PREFIX = Buffer.from('3059301306072a8648ce3d020106082a8648ce3d030107034200', 'hex');

/** Curve order n of P-256, for low-S normalisation. */
const ORDER = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551n;
const HALF_ORDER = ORDER >> 1n;

/**
 * Imports a P-256 public key sent as its 65-byte X9.63 form (`0x04 || X || Y`,
 * CryptoKit's `x963Representation`). Throws if the bytes are not a point on the curve.
 */
export function p256PublicKey(x963: Uint8Array): KeyObject {
  if (x963.length !== 65 || x963[0] !== 0x04) throw new TypeError('not an uncompressed P-256 point');
  return createPublicKey({ key: Buffer.concat([SPKI_PREFIX, x963]), format: 'der', type: 'spki' });
}

export function isP256Point(x963: Uint8Array): boolean {
  try {
    p256PublicKey(x963);
    return true;
  } catch {
    return false;
  }
}

/** X9.63 bytes of a P-256 public key object. */
export function x963FromKey(key: KeyObject): Buffer {
  const jwk = key.export({ format: 'jwk' });
  if (jwk.crv !== 'P-256' || jwk.x === undefined || jwk.y === undefined) throw new TypeError('not a P-256 key');
  return Buffer.concat([Buffer.from([0x04]), Buffer.from(jwk.x, 'base64url'), Buffer.from(jwk.y, 'base64url')]);
}

/**
 * ECDSA signatures are malleable: (r, s) and (r, n - s) both verify. Mapping every
 * signature to its low-S twin gives one canonical value, so the replay store can't be
 * dodged by resubmitting the twin of a captured proof.
 */
export function lowS(rawSignature: Uint8Array): Buffer {
  if (rawSignature.length !== 64) throw new TypeError('expected a 64-byte r || s signature');
  const out = Buffer.from(rawSignature);
  const s = BigInt(`0x${out.subarray(32).toString('hex')}`);
  if (s > HALF_ORDER) Buffer.from((ORDER - s).toString(16).padStart(64, '0'), 'hex').copy(out, 32);
  return out;
}

/** Converts a DER ECDSA signature (AWS KMS output) to the raw 64-byte `r || s` form. */
export function derToRawSignature(der: Uint8Array): Buffer {
  const bytes = Buffer.from(der);
  let offset = 0;
  const expect = (value: number): void => {
    if (bytes[offset] !== value) throw new TypeError('malformed DER signature');
    offset += 1;
  };
  const readLength = (): number => {
    const first = bytes[offset++];
    if (first === undefined || first >= 0x80) throw new TypeError('malformed DER signature');
    return first;
  };
  const readInteger = (): Buffer => {
    expect(0x02);
    const length = readLength();
    let value = bytes.subarray(offset, offset + length);
    offset += length;
    while (value.length > 32 && value[0] === 0) value = value.subarray(1); // sign padding
    if (value.length > 32) throw new TypeError('malformed DER signature');
    return Buffer.concat([Buffer.alloc(32 - value.length), value]);
  };
  expect(0x30);
  if (readLength() !== bytes.length - offset) throw new TypeError('malformed DER signature');
  const r = readInteger();
  const s = readInteger();
  if (offset !== bytes.length) throw new TypeError('malformed DER signature');
  return Buffer.concat([r, s]);
}
