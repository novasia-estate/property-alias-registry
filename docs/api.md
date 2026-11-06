# API contract

`new(entries)` validates all entries before returning a registry. Malformed construction raises a Lua error. Each dense-array entry supplies a nonempty existing entity_id, original alias, explicit scope and provenance string. Repeated entries are retained as observations; candidate identities are deduplicated. Empty registries are valid.

`registry:resolve(label, scope)` returns a value for invalid queries as well as known/unknown names. Scope is optional, case-sensitive and edge-trimmed. Omitting scope searches all matching entries and may expose ambiguity across sources. Matches and candidates are fresh copies; caller mutation does not modify the registry. The entity_id field exists only for a unique result.

`registry:audit()` returns entry_count, scoped_conflicts and unscoped_ambiguities. A conflict contains a normalized key and candidate IDs; scoped conflicts also include scope. Results are deterministic for the same runtime string ordering and input. No normalized key or identity is automatically rewritten.

`registry:entries()` returns copies of the supported fields. `registry:with(extra_entries)` returns a newly validated registry. If new entries are invalid, the original registry remains usable and unchanged. Registry methods are regular Lua table methods, not an access-control boundary or a sandbox against hostile Lua code.

`VERSION` reports the library version; `normalize` exposes the key policy for preview. The module performs no I/O. Applications choose persistence formats and are responsible for authenticating upstream records and validating claims made in provenance text.
