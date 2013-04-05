module(..., package.seeall)

function read_json_file(file_name)
    JSON = (loadfile 'lib/JSON.lua')()
    local file = io.open(file_name, 'r')
    local output = JSON:decode( file:read("*all") )
    file:close()
    return output
end

function encode_json_file(object, file_name)
    JSON = (loadfile 'lib/JSON.lua')()
    local output = JSON:encode_pretty( object )
    local file = io.open(file_name, 'w')
    file:write(output)
    file:close()
    return output
end
