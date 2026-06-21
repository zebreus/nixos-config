# Glossary (terms this design defines)

These are _our_ terms for _this_ config; they are defined here, not borrowed from any
external tool.

## Structure & namespace

- **Meta options** — the option _declarations_ describing the fleet, in one file,
  `modules/helpers/machines.nix`.
- **Meta config** — the _values_ that fill those options (the actual fleet), in
  `machines.nix` at the repo root.
- **`meta.machines.<host>`** — a machine's record: the options set for that machine
  (read/write), plus its read-only **projected services**.
- **`meta.services.<svc>`** — a **meta service** (read/write).
- **Meta service** — a capability declared in `meta.services`, assigned to machines by name
  with a cardinality (or, for `none`, required global config assigned to no machine).
- **Projected service** — the read-only per-machine view of a meta service,
  `meta.machines.<host>.<svc>.{enable, …config}`, derived from the assignment. _Every_ meta
  service is projected into _every_ machine; `enable` reflects assignment (always `false`
  for `none`), and config fields are always present (never null). This is what consumer
  modules read (so the consumer read API is preserved).
- **Service Cardinality** — how many machines a service may be assigned to. Each value, with the
  type that makes a violation unrepresentable:
  - **exactlyOne** — required, one machine (`host : enum hostNames`).
  - **atMostOne** — zero or one (`host : nullOr (enum hostNames)`, default `null`; the
    service submodule itself is always present).
  - **atLeastOne** — one or more (`hosts : nonEmptyListOf (enum hostNames)`).
  - **any** — zero or more (`hosts : listOf (enum hostNames)`).
  - **none** — required global config, not tied to any machine: no host field; projected
    into every machine with `enable = false` and config always present, so every machine
    can rely on it.
