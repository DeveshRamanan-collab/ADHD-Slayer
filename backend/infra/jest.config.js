module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  testMatch: ['**/*.test.ts'],
  transform: {
    '^.+\\.tsx?$': ['@swc/jest'],
  },
  // Synthesising two full environments with cdk-nag takes a few seconds per file.
  testTimeout: 120000,
  setupFilesAfterEnv: ['aws-cdk-lib/testhelpers/jest-autoclean'],
};
