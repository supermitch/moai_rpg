--[[ Map class ]]

module(..., package.seeall)

Map = {}
Map.__index = Map

function Map.new(name)
    local map = {}                  -- instance
    setmetatable(map, Map)
    map.name = name or 'default'
    map.grid = {}                   -- Init empty grid
    return map
end

function Map:get_name()
    --[[ Return name ]]
    return self.name
end

function Map:compass_cell_offset(direction)
    --[[ Get the cell offset in the given compass direction. Applying the
    cell offset to a current set of coords will give the next cell. ]]
    if direction == 'n' then
        return -1, 0
    elseif direction == 'e' then
        return 0, 1
    elseif direction == 's' then
        return 1, 0
    elseif direction == 'w' then
        return 0, -1
    else
        print("Bad compass direction: ", direction)
    end
end

function Map:next_cell(i, j, direction)
    --[[ Given a cell index, return the next cell in a given direction ]]
    local di, dj = self:compass_cell_offset(direction)
    if di and dj then
        return i + di, j + dj
    end
end

function Map:compass_opposite(direction)
    --[[ Return the opposite direciton to the argument. ]]
    local dict = {n='s', e='w', s='n', w='e'}
    local opposite = dict[direction]
    if not opposite then
        print("Bad compass direction: ", direction)
    end
    return opposite
end

function Map:walkable(i, j)
    --[[ Return true if cell i,j is walkable. ]]
    -- if row exists and cell exists and cell is walkable
    if self.grid[i] and self.grid[i][j] and map.grid[i][j].walkable then
        return true
    end
end

function Map:idx_to_coords(i, j)
    -- Return the position (in world coords) of the tile at indices [i][j]
    return self.grid[i][j]:getLoc()
end

function Map:coords_to_idx(X, Y)
    --[[ Return the [i][j] indices of the tile closest to given world
    coords (X, Y). ]]
    --[[ TODO: At the moment off-map locations will return a tile, which
    shoud probably return nil. ]]
    local cur_min = math.huge
    for i, row in ipairs(self.grid) do
        for j, tile in ipairs(row) do
            local dist = helpers.math.distance(X, Y, tile:getLoc())
            if dist < cur_min then
                cur_min = dist
                index_i = i
                index_j = j
            end
        end
    end
    return index_i, index_j
end

function Map:get_tile(X, Y)
    -- Return the actual tile at the world coordinate (X, Y)
    i, j = self:coords_to_idx(X, Y)
    if i == nil or j == nil then return nil end
    return self.grid[i][j]
end

function Map:get_prop(X, Y)
    -- Return the actual prop under the world coords (X, Y)
    local partition = self:getPartition()
    return partition:propForPoint(X, Y, 0)
end


function Map:load_level(map_viewport, level)
    -- Loads a level matrix into the map layer
    self.layer = MOAILayer2D.new()
    self.layer:setViewport(map_viewport)
    
    local map_array = helpers.json.decode_file(level)

    self:load_terrain(map_array)    -- Terrain and appearance
end

function Map:load_terrain(map_array)

    local grass = MOAIGfxQuad2D.new()
    grass:setTexture("assets/images/map/grass_1.png")
    grass:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand = MOAIGfxQuad2D.new()
    sand:setTexture("assets/images/map/sand_1.png")
    sand:setRect(-0.5, -0.5, 0.5, 0.5)

    local grass_rock = MOAIGfxQuad2D.new()
    grass_rock:setTexture("assets/images/map/rock_1.png")
    grass_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand_rock = MOAIGfxQuad2D.new()
    sand_rock:setTexture("assets/images/map/rock_2.png")
    sand_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    local ocean = MOAIGfxQuad2D.new()
    ocean:setTexture("assets/images/map/ocean_1.png")
    ocean:setRect(-0.5, -0.5, 0.5, 0.5)

    for i, row in pairs(map_array) do
        if self.grid[i] == nil then -- If grid row doesn't exit
            self.grid[i] = {}       -- Init empty grid row
        end 
        for j, value in pairs(row) do
            local prop = MOAIProp2D.new()
            local tile = {}
            if value == 1 then
                prop:setDeck(grass)
                tile.name = 'grass'
            elseif value == 2 then
                prop:setDeck(sand)
                tile.name = 'sand'
            elseif value == 3 then
                prop:setDeck(grass_rock)
                tile.name = 'grass_rock'
                tile.walkable = false
            elseif value == 4 then
                prop:setDeck(sand_rock)
                tile.name = 'sand_rock'
                tile.walkable = false
            elseif value == 5 then
                prop:setDeck(ocean)
                tile.name = 'ocean'
                tile.walkable = false
            else
                error("Invalid map value at ("..i..","..j..") = "..value)
                prop:setDeck(grass)
            end
            if tile.walkable == nil then
                tile.walkable = true
            end
            prop:setLoc((j-0.5-scale_width/2), (scale_height/2-(i-0.5)))
            self.layer:insertProp(prop)

            tile.X, tile.Y = prop:getLoc()
            function tile:getLoc()
                return self.X, self.Y
            end
            tile.width = 1  -- Assumed, for now
            tile.height = 1
            self.grid[i][j] = tile
        end
    end
end
