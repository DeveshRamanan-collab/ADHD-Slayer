import { writeFile } from 'node:fs/promises';
import { generateOpenApi } from '../openapi.js';

/** `npm run openapi`: writes openapi.json at the package root. Commit it; a test fails when it is stale. */
const target = new URL('../../openapi.json', import.meta.url);
await writeFile(target, await generateOpenApi());
process.stdout.write('wrote openapi.json\n');
