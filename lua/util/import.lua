local function from(package_name)
  local pkg = require(package_name)
  return {
    import=function(self, ...)
      local field_names = {...}
      local result = {}
      for i=1, #field_names do
        local field_name = field_names[i]
        local field = pkg[field_name]
        assert(field, string.format(
          'package %s does not have a field named %s',
          package_name, field_name))
        result[i] = field
      end
      return table.unpack(result)
    end
  }
end

return from