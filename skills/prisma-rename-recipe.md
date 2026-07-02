---
name: prisma-rename-recipe
description: A repeatable recipe for renaming Prisma fields and enum values in production with in-transaction data conversion. Use when renaming a field in schema.prisma (especially with a type conversion such as Int→Decimal) or an enum value. Includes an SQL template, a consumer-hunt checklist, and a parallel-session safety protocol.
triggers:
  - "prisma rename"
  - "rename field"
  - "rename column"
  - "type conversion"
---

# Prisma Rename Recipe

A recipe for safely renaming Prisma fields and enum values in production. Optimized for:
- Data conversion in a single transaction (`USING value::numeric / 100`)
- Enum rename in a single transaction (text-cast trick, not `ALTER TYPE ADD VALUE`)
- Finding all consumers (TS, seed, tests, UI, sub-agents)
- Safety with parallel working sessions

## When to Activate

- Rename a Prisma model field (`oldName → newName`)
- Change a field type (`Int → Decimal`, `String → Json`, etc.) with data migration
- Rename an enum value (`BONUS_CREDIT_CENTS → BONUS_CREDIT_UNIT`)
- Drop a field + create a new one with data migration

## Time Estimate

Budget 2-3 hours minimum for a **single** rename. Several renames scale that up.

What eats the time:
- Finding all consumers (15-30 min per rename)
- Adapting seed scripts (often outside tsconfig)
- Adapting tests and mocks
- Parallel sessions can rebase your schema.prisma → re-apply
- Reviewer gate before deploy (database review + security review + typecheck review)

## Steps

### Step 1: Decide — data migration or plain rename?

**Plain rename (no data migration)** — when the new name describes the old data 1:1:
- `legacyName → cleanName` with the same type
- `priceMonthly Int (minor units) → priceMonthlyMinorUnits Int` (explicit name)

```sql
ALTER TABLE "Plan" RENAME COLUMN "priceMonthly" TO "priceMonthlyMinorUnits";
```

**With data migration** — when the type/unit changes:
- `Int (minor units) → Decimal (major units)` (needs `/100`)
- `String → Json` (needs parse)
- `enum old_value → new_value`

```sql
ALTER TABLE "Plan"
  ALTER COLUMN "priceMonthly" TYPE NUMERIC(12,2)
  USING ("priceMonthly"::numeric / 100);
```

### Step 2: Create the migration

Create `prisma/migrations/<timestamp>_<description>/migration.sql`. Timestamp in `YYYYMMDDHHMMSS` format.

**Template for type change + rename + data migration:**

```sql
-- <description>
--
-- What this does, and the source of truth.

ALTER TABLE "Table"
  ALTER COLUMN "oldName" TYPE NEW_TYPE
  USING ("oldName"::CAST_TYPE / DIVISOR);
-- (if a rename is needed — separate statement)
ALTER TABLE "Table" RENAME COLUMN "oldName" TO "newName";
```

**Template for enum rename (text-cast trick):**

`ALTER TYPE _name_ ADD VALUE 'NEW'` requires a commit BEFORE the value can be used — so it cannot run in the same transaction as an `UPDATE`. Use the text-cast trick instead:

```sql
-- Create a NEW enum alongside the old one
CREATE TYPE "EnumName_new" AS ENUM (
  'VALUE_A',
  'VALUE_B',
  'NEW_VALUE'  -- was OLD_VALUE
);

-- Drop the DEFAULT (if any)
ALTER TABLE "TableUsingEnum"
  ALTER COLUMN "field" DROP DEFAULT,
  ALTER COLUMN "field" TYPE TEXT;

-- Convert the data
UPDATE "TableUsingEnum"
  SET "field" = 'NEW_VALUE'
  WHERE "field" = 'OLD_VALUE';

-- Switch the type to the new enum + restore the DEFAULT
ALTER TABLE "TableUsingEnum"
  ALTER COLUMN "field" TYPE "EnumName_new" USING ("field"::"EnumName_new"),
  ALTER COLUMN "field" SET DEFAULT 'VALUE_A';

-- Drop the old enum, rename the new one
DROP TYPE "EnumName";
ALTER TYPE "EnumName_new" RENAME TO "EnumName";
```

**Transactionality:** `prisma migrate deploy` wraps each migration file in a transaction. The text-cast trick is safe in a single transaction (it does not use `ALTER TYPE ADD VALUE`).

**ACCESS EXCLUSIVE LOCK:** `ALTER COLUMN TYPE` with `USING` performs a **full table rewrite** and takes an ACCESS EXCLUSIVE LOCK. Writes to the table wait for it to finish (usually <2 s on small tables). For large production tables, prefer a maintenance window.

### Step 3: Update schema.prisma

```prisma
model Plan {
  // Major-unit decimal (NUMERIC(12,2)). Was Int minor units (name LIED).
  priceMonthly  Decimal? @db.Decimal(12, 2)
}

enum PromoBonusKind {
  DISCOUNT
  BONUS_MINUTES
  BONUS_STORAGE_GB
  // Renamed from BONUS_CREDIT_CENTS (was stored in minor units).
  BONUS_CREDIT_UNIT
}
```

Then regenerate the client:

```bash
npm run db:generate
```

**If the Prisma client is cached with the old version** (you see old field names in IntelliSense):
```bash
rm -rf node_modules/.prisma node_modules/@prisma/client
npm run db:generate
```

### Step 4: Hunt all consumers

**This is the most painful part.** typecheck will NOT show all of them — because:
- Seed scripts (`seed.ts`, `seed-*.ts`, `*-update*.ts`) are often outside tsconfig
- Tests with mocks (`*.spec.ts`) may use literal objects with old names
- LLM data-source modules — zod schemas with literal keys
- DTOs in a shared-types package may keep the old name
- Frontend pages with locally-declared interfaces (not imported from shared types)

**Search checklist:**

```bash
# 1. TypeScript touchpoints (everything, including outside tsconfig)
grep -rn "<oldFieldName>\|<OLD_ENUM_VALUE>" \
  . --include="*.ts" --include="*.tsx" 2>/dev/null | \
  grep -v node_modules | grep -v ".next" | grep -v "/dist/"

# 2. Prisma seed scripts (separately — often outside tsconfig)
ls prisma/*.ts | xargs grep -l "<oldFieldName>"

# 3. Frontend local interfaces (typecheck won't compare them to shared types)
grep -rn "interface.*\(Plan\|Payment\)" \
  <web-app-dir> --include="*.tsx" --include="*.ts"

# 4. LLM data sources (zod schemas)
grep -rn "z.object\|z.record\|<oldFieldName>" \
  <llm-modules-dir> --include="*.ts"

# 5. Mock fixtures
grep -rn "<oldFieldName>:" \
  --include="*.spec.ts" --include="*.fixture.ts" .

# 6. Comments with the stale name (can mislead future developers)
grep -rn "<oldFieldName>" --include="*.md" .
```

**For each match:**
- TypeScript code → rename (`tsc` will catch it)
- Comments → update
- Seed scripts → rename **AND** adjust values if there was a type change
- Tests → update mocks **AND** assertions
- Markdown docs → update mentions

### Step 5: Update the backend boundary

If there was a type change (`Int → Decimal`):

```ts
// BEFORE (Int):
return {
  price: plan.priceMonthly ?? 0,  // number directly
};

// AFTER (Decimal):
return {
  price: plan.priceMonthly?.toNumber() ?? null,  // Decimal → number
};
```

**Where to look for boundaries:**
- Prisma `findMany / findUnique / findFirst` → map into DTO
- Prisma `_sum.amount`, `_avg.amount`, `_min.amount`, `_max.amount` → also Decimal
- Prisma write paths (`create / update / upsert`): accept number (Prisma coerces to Decimal)

**Remove dead helpers:**
- If a `toMinorUnits` helper existed for Prisma writes — it is no longer needed (write major units as-is into Decimal). Remove it.

### Step 6: Reviewer gate

MANDATORY BEFORE deploy — run in parallel:

```
- database review: migration SQL + schema + indexes + ACCESS LOCK + rollback + parallel-session safety
- security review: money flow + DTO boundaries + LLM contexts + auth gaps
- typescript review: Decimal.toNumber on boundary + DTO consistency frontend↔backend + dead code
- QA: smoke UI flows on affected pages
```

Fix all BLOCKER/HIGH findings BEFORE `prisma migrate deploy`.

### Step 7: Deploy

Deploy via your standard pipeline. If migrations run via a prestart hook, note that the ACCESS EXCLUSIVE LOCK can block old pods for ~2-30 s during `prisma migrate deploy` — a brief outage is possible on large tables (not critical on small ones).

### Step 8: Post-deploy verification

```bash
# 1. Open psql and check live data
psql "$DATABASE_URL" \
  -c 'SELECT slug, "<newFieldName>" FROM "Plan" LIMIT 10;'

# 2. Health checks against the deployed API
# 3. Smoke the real UI on affected pages
```

## Parallel-session safety

Lesson learned: while doing a rename, a parallel session was editing the same `schema.prisma` (unrelated models). **Twice, one branch clobbered the other's changes** — requiring a manual merge via stash.

**Rule:** before `git add prisma/schema.prisma`:

```bash
# 1. Pull the last shared state
git fetch origin main

# 2. Diff vs origin
git log HEAD..origin/main -- prisma/schema.prisma

# 3. If a parallel session touched the schema:
#    a. git stash your changes
#    b. git pull --rebase
#    c. git stash pop → manual merge conflict
#    d. Do not overwrite — keep both sets
```

## Rollback

If the migration is already in production and needs reverting:

```sql
-- Reverse type change (Decimal → Int):
ALTER TABLE "Plan"
  ALTER COLUMN "priceMonthly" TYPE INTEGER
  USING ROUND("priceMonthly" * 100);

-- Reverse enum rename — repeat the text-cast trick in the other direction.
```

**Money-loss check:** Decimal(12,2) → Int (×100) — lossless only if the original values were whole minor units. Sub-unit values round to the nearest whole minor unit.

## Anti-patterns (post-mortem)

1. **"typecheck is green — the migration is ready"** — no. You need multiple reviewers + a clean build + a smoke test. typecheck does not see seed scripts and does not compare locally-declared frontend interfaces.

2. **"I know the DB stores minor units because the code divides by 100 everywhere"** — verify live data via psql BEFORE committing, so a reviewer's false interpretation cannot slip through.

3. **"ALTER TYPE ADD VALUE is simpler"** — yes, but it requires a commit before use → it does not work in the same transaction as an `UPDATE`. Use the text-cast trick.

4. **"I'll mark the work DONE and sort out seed later"** — NO. Seed scripts sit outside tsconfig → `db:seed` fails weeks after release, when nobody remembers what changed in the schema. Fix it in the same commit.
