import { PGlite, types } from '@electric-sql/pglite';
let t = Date.now();
const db = new PGlite('memory://');
await db.waitReady;
console.log('init ms', Date.now() - t);
await db.exec(`create table t (id int8, b bytea, d date, ts timestamptz, j jsonb, n numeric, u uuid, arr text[]); select 1; select 2;`);
const r = await db.query(`insert into t values ($1,$2,$3,$4,$5,$6,$7,$8) returning *`, [5, Buffer.from([1,2,3]), '2026-09-30', new Date('2026-09-30T01:02:03.456Z'), JSON.stringify({a:1}), '1.50', '0199a8d2-7a2e-7cc3-8b6e-1f2a3b4c5d6e', ['x','y']]);
const row = r.rows[0];
for (const [k,v] of Object.entries(row)) console.log(k, typeof v, v?.constructor?.name, JSON.stringify(v));
console.log('rowCount/affected', r.rowCount, r.affectedRows);
const r2 = await db.query(`insert into t (j) values ($1) returning j`, [{a:2}]);
console.log('obj jsonb', JSON.stringify(r2.rows[0].j));
const r3 = await db.query(`insert into t (j) values ($1::jsonb) returning j`, ['{"a":3}']);
console.log('str jsonb cast', JSON.stringify(r3.rows[0].j), typeof r3.rows[0].j);
const r3b = await db.query(`insert into t (j) values ($1::text::jsonb) returning j`, ['{"a":3}']);
console.log('str text::jsonb cast', JSON.stringify(r3b.rows[0].j), typeof r3b.rows[0].j);
const r4 = await db.query(`select pg_advisory_xact_lock(42) as l`);
console.log('adv lock', JSON.stringify(r4.rows));
const r5 = await db.query(`select count(*) as c from t`);
console.log('count', typeof r5.rows[0].c, r5.rows[0].c);
const r6 = await db.query(`update t set n = 2 where id is null`);
console.log('update rowCount', r6.rowCount, r6.affectedRows);
t = Date.now();
const c = await db.clone();
console.log('clone ms', Date.now() - t, (await c.query('select count(*) c from t')).rows);
try { await db.query('select 1; select 2'); } catch (e) { console.log('multi via query err:', e.message); }
try { await db.query('insert into t (u) values ($1)', ['not-a-uuid']); } catch (e) { console.log('err fields', e.code, Object.keys(e)); }
await db.close();
