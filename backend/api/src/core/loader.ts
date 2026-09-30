import { readdir } from 'node:fs/promises';

/**
 * Directory-based discovery for modules (`src/modules/<name>/index.ts`), jobs
 * (`src/jobs/<name>.ts`) and providers (`src/providers/<name>.ts`), so adding a feature
 * never means editing a shared list.
 */

/** `.ts` when running from source (tsx, vitest), `.js` when running the build in dist/. */
export const SOURCE_EXTENSION = import.meta.url.endsWith('.ts') ? '.ts' : '.js';

/** `src/` or `dist/`. */
export const SOURCE_ROOT = new URL('../', import.meta.url);

export function sourceFile(dir: URL, baseName: string): URL {
  return new URL(`${baseName}${SOURCE_EXTENSION}`, dir);
}

/** Sorted names of the subdirectories; empty when `dir` is missing. */
export async function listDirectories(dir: URL): Promise<string[]> {
  const entries = await readEntries(dir);
  return entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name).sort();
}

/** Sorted base names of the source files directly in `dir`; empty when `dir` is missing. */
export async function listSourceFiles(dir: URL): Promise<string[]> {
  const entries = await readEntries(dir);
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(SOURCE_EXTENSION) && !entry.name.endsWith(`.d${SOURCE_EXTENSION}`))
    .map((entry) => entry.name.slice(0, -SOURCE_EXTENSION.length))
    .sort();
}

async function readEntries(dir: URL) {
  try {
    return await readdir(dir, { withFileTypes: true });
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
    throw error;
  }
}
