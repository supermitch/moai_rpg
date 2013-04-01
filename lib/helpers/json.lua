module(..., package.seeall)

function read_json_file(file_name)
    JSON = (loadfile 'lib/JSON.lua')()
    local file = io.open(file_name, 'r')
    local output = JSON:decode( file:read("*all") )
    file:close()
    return output
end
