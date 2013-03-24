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
            local dist = mh.distance(X, Y, tile:getLoc())
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

    level={{4,2,2,2,2,1,1,1,1,1,1,1,1,1,1,4}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2}
          ,{2,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2}
          ,{1,2,2,2,2,2,1,1,3,1,1,1,2,2,2,4}
          ,{1,2,2,2,2,2,1,1,1,1,1,1,2,2,4,4}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,4,4,4}
          ,{2,1,2,1,2,1,2,1,2,1,2,1,2,4,4,4}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,4,2,4}
          ,{1,1,1,2,2,1,1,1,1,1,1,1,1,2,2,2}
          ,{1,1,1,1,1,1,3,1,3,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,3,3,1,1,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{3,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2}
          ,{3,3,1,1,1,1,1,1,1,1,1,1,1,1,2,4}}

    self.layer = MOAILayer2D.new()
    self.layer:setViewport(map_viewport)

    local grass = MOAIGfxQuad2D.new()
    grass:setTexture("images/maps/grass_1.png")
    grass:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand = MOAIGfxQuad2D.new()
    sand:setTexture("images/maps/sand_1.png")
    sand:setRect(-0.5, -0.5, 0.5, 0.5)

    local grass_rock = MOAIGfxQuad2D.new()
    grass_rock:setTexture("images/maps/rock_1.png")
    grass_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand_rock = MOAIGfxQuad2D.new()
    sand_rock:setTexture("images/maps/rock_2.png")
    sand_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    for i, row in pairs(level) do
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
