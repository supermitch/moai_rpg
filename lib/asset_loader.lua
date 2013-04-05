module(..., package.seeall)

function read(path, extension)
    local asset_table = {}
    local contents = {}
    local files = MOAIFileSystem.listFiles (path)
    if files then
        for i, v in ipairs(files) do
            if v:match('%.'..extension..'$') then
                contents = helpers.json.decode_file(path..'/'..v)
                asset_table[contents.kind] = contents
            end
        end
    end
    return asset_table
end
