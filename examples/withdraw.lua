local aliases=require('property_alias')
local old={entity_id='DEMO-A',alias='Court',scope='demo',provenance='supplied older synthetic mapping'}
local current={entity_id='DEMO-B',alias='Court',scope='demo',provenance='supplied current synthetic mapping'}
local registry=aliases.new({old,current})
local next_registry,report=registry:without({old})
assert(registry:resolve('Court','demo').status=='ambiguous')
assert(next_registry:resolve('Court','demo').entity_id=='DEMO-B')
assert(report.removed_count==1)
print('Synthetic observation withdrawal passed; this does not verify a real property identity.')
