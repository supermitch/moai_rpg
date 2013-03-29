module(..., package.seeall)

function read_json_file(file_name)
    print("trying!")
    JSON = (loadfile 'lib/JSON.lua')()
    print(file_name)
    local file = io.open(file_name, 'r')
    local output = JSON:decode( file:read("*all") )
    file:close()
    return output
end
