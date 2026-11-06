# Property Alias Registry

A dependency-free Lua module for looking up **explicitly authored aliases** of existing property identifiers. It preserves original UTF-8 names, keeps source/locality scopes distinct and returns ambiguity when a label points to several identifiers. It does not create identities, transliterate names or perform fuzzy deduplication.

Developed by [NovAsia Estate](https://novasia.estate/). MIT licensed. Useful in Lua/OpenResty ingestion and catalogue applications that need to reconcile known marketing names without silently joining different buildings.

## Install

```sh
luarocks install property-alias-registry
```

Compatible with Lua 5.1–5.4 and LuaJIT. No runtime dependency outside Lua.

## Resolve known names in an explicit scope

```lua
local aliases = require('property_alias')
local registry = aliases.new({
  {entity_id='DEMO-A', alias='Garden Court', scope='demo:central',
    provenance='authored synthetic fixture A'},
  {entity_id='DEMO-A', alias='Гарден Корт', scope='demo:central',
    provenance='explicit synthetic Cyrillic alias A'},
  {entity_id='DEMO-B', alias='Garden Court', scope='demo:outer',
    provenance='authored synthetic fixture B'}
})

assert(registry:resolve('Garden Court').status == 'ambiguous')
assert(registry:resolve('GARDEN COURT', 'demo:central').entity_id == 'DEMO-A')
assert(registry:resolve('Гарден Корт', 'demo:central').entity_id == 'DEMO-A')
assert(registry:resolve('Garden Cort').status == 'unknown')
```

All examples are invented. They do not identify real buildings or establish that a marketing name is an official name.

## Four outcomes

`registry:resolve(label, optional_scope)` returns `resolved`, `ambiguous`, `unknown` or `invalid`.

- `resolved`: exactly one distinct existing identifier matched. `entity_id` is populated.
- `ambiguous`: several identifiers matched. Sorted `candidates` and original matching entries are returned; no winner is selected.
- `unknown`: no explicitly stored alias matched under the supplied scope.
- `invalid`: malformed UTF-8, disallowed controls, blank/oversized label or invalid scope. The result contains an error code instead of raising for a query.

Every result retains `query`; valid queries also include the normalized `key`. Matching entries retain their original alias, scope and provenance. Multiple observations pointing to the same identifier do not create false ambiguity.

## Audit before using a registry

```lua
local report = registry:audit()
print(report.entry_count)
print(#report.scoped_conflicts)
print(#report.unscoped_ambiguities)
```

Scoped conflicts identify a normalized label mapped to multiple IDs within one scope. Unscoped ambiguity also includes names reused across otherwise separate scopes. The report exposes conflicts for review; it does not automatically rewrite aliases or choose an authority.

`registry:entries()` returns defensive copies. `registry:with(extra_entries)` creates a new validated registry and leaves the original unchanged, including when validation fails. Inputs and returned matches can be changed by callers without mutating the stored registry.

## Deliberately limited normalization

The versioned key policy folds ASCII A–Z, collapses ordinary spaces/tabs, maps NBSP/narrow NBSP/ideographic space to a space, selected Unicode dashes to `-`, and curly single quotes to `'`. Other Unicode characters are preserved after strict UTF-8 validation. Non-ASCII case folding, NFC/NFKC, transliteration, accent removal and confusable folding are **not** implemented. Explicit aliases are required for different scripts and case variants outside ASCII.

Malformed UTF-8, most control characters and directional embedding/isolate controls reject. This is a narrow input policy, not a complete Unicode security or spoofing detector. [Exact policy](https://github.com/novasia-estate/property-alias-registry/blob/main/docs/key-policy.md).

## Contracts and limits

Construction requires a dense array of at most 10,000 entries. Each needs `entity_id`, `alias`, `scope`, and `provenance`. Entity ID/scope limits are 256 bytes, provenance 2,048 bytes and aliases 4,096 bytes. IDs and scopes retain case and are trimmed at their ASCII whitespace edges. Missing provenance or malformed entries reject the whole construction. Unknown fields are not preserved.

Provenance is supplied text, not verified evidence. Identical IDs across scopes are treated as the same identity because the caller supplied that identifier. The library cannot authenticate data, establish legal names or detect distinct IDs referring to one real property. [API contract](https://github.com/novasia-estate/property-alias-registry/blob/main/docs/api.md) · [Integration guide](https://github.com/novasia-estate/property-alias-registry/blob/main/docs/integration.md).

## Reproduce

```sh
lua tests/run.lua
# After installing the module:
lua examples/resolve.lua
```

The six-entry synthetic catalogue includes Thai/Cyrillic aliases, names reused across scopes and one intentional normalization collision. Behavioral checks cover all four outcomes, Unicode boundaries, exact scope behavior, no-fuzzy/no-transliteration behavior, mutation isolation and collision auditing. No network, storage or automatic logging is implemented by the module; the example prints only its authored fixtures.
