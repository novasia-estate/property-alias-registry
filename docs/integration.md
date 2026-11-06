# Catalogue and OpenResty integration

Build an alias registry from a reviewed, explicit catalogue during application initialization. Keep original aliases and provenance alongside canonical IDs in your own source of truth. Scope labels can describe a feed, locality or another deliberately chosen namespace; the library assigns no geographic meaning to them.

For each incoming name, call resolve with the known source scope. Route resolved records to the existing entity, ambiguous records to review, unknown names to a new-alias queue and invalid names to input correction. Do not convert ambiguous or unknown outcomes to the first candidate or a newly minted identity automatically.

Construct an updated registry with with() or new() after review and replace your application's reference atomically. This does not provide cross-worker synchronization; OpenResty applications must choose their own deployment/shared-state strategy. The module uses no ngx APIs, so the same behavior works outside OpenResty.

The library accepts Lua tables, including tables your application parsed with a suitable JSON library. It never evaluates a user-supplied Lua file. The bundled example catalogue is trusted authored code; do not use dofile/load on untrusted catalogue uploads. No JSON/CSV parser or network client is bundled.

Store provenance that actually explains the alias decision. A URL string is not proof that the page was read or that its publisher authorized the alias. Avoid client personal details in provenance when the registry will be shared publicly.
