local aliases = require('property_alias')
local registry = aliases.new(require('examples.catalogue'))
for _,query in ipairs({{'Garden Court'}, {'Garden Court','demo:central'},
  {'การ์เดน คอร์ต','demo:central'}, {'River-House','demo:central'}, {'Unknown'}}) do
  local result=registry:resolve(query[1],query[2])
  print(result.query,result.status,table.concat(result.candidates,', '))
end
local report=registry:audit()
print('Entries',report.entry_count,'scoped conflicts',#report.scoped_conflicts,
  'unscoped ambiguous keys',#report.unscoped_ambiguities)
