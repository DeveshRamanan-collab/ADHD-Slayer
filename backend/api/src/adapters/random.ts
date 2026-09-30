import { randomBytes } from 'node:crypto';

/** Injectable source of cryptographic random bytes (tokens, secrets). Tests swap in a seeded one. */
export interface Random {
  bytes(size: number): Buffer;
}

export const cryptoRandom: Random = {
  bytes: (size) => randomBytes(size),
};
