import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/**/*.test.ts'],
    // Each test app boots an in-memory Postgres (PGlite); the first boot per worker runs migrations.
    testTimeout: 30_000,
    hookTimeout: 60_000,
  },
});
