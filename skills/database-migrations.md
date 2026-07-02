---
name: database-migrations
description: How to change a production database schema without breaking existing flows. Irreversible in prod — treat with care. Activates on schema edits, migrations, column renames.
triggers: ["migration", "schema change", "rename column", "alter table"]
applies_to: ["prisma/schema.prisma", "prisma/migrations/**"]
---

# Database migrations — the safe recipe

> Sanitized example skill. The ORM is generic here; the discipline is verbatim.

## The core danger

A production migration is **irreversible in practice**. You can't `undo` a dropped column once real
rows are gone. And a rename is never just a rename — every consumer (API DTOs, the frontend, background
workers, cached queries) referencing the old name breaks the moment the column changes underneath it.

So the rule: a schema change is a **Phase-2 planning decision**, not something you improvise mid-code.

## Never run two migrations from two sessions at once

If two live sessions each generate a migration against the same DB, they interleave and corrupt the
migration history. One session at a time touches the schema. (This is enough of a footgun that it's a
standing rule in the constitution.)

## The rename recipe (the expensive one)

Renaming a column safely is a multi-step dance, not one `ALTER`:

1. **Inventory the consumers first.** Grep the whole monorepo for the old field name — API, shared
   types, frontend, workers, seed scripts. You cannot migrate what you haven't found.
2. **Add the new column** alongside the old (additive, safe). Backfill it.
3. **Ship the code** that writes both and reads the new one.
4. **Only then** drop the old column, in a later migration, once nothing reads it.

Trying to do this in one step against a live table with traffic is how you get a 15-minute outage.

## The API-contract audit

Any schema change that drops/renames a column read by the frontend triggers a contract audit: inventory
every endpoint that returns the field, and decide per-endpoint what happens. A field that quietly changes
type or meaning is worse than one that's removed — the removal fails loudly; the semantic drift fails
silently, weeks later.

## The reviewer gate

Touching the schema is on the mandatory-review list: the DB reviewer signs off before it ships, and the
rename recipe is cross-checked. The deploy will not run without that verdict recorded.

## The lesson underneath all of this

The cheapest migration is the one you didn't need because you extended an existing model instead of
adding a parallel one. Phase 2 always asks first: *can this reuse what's already there?* Most "we need a
new table" turns out to be "we need three more columns on a table we already have."
