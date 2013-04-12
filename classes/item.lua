--[[ Item class ]]

module(..., package.seeall)

Item = {}
Item.__index = Item

function new(name, kind, i, j)
    --[[ Get instance class and call loading methods ]]
    local item = Item.instantiate(name, kind)
    item:load_attribs()
    item:load_gfx()
    item.prop:setLoc(map:idx_to_coords(i, j))
    return item
end

function Item.instantiate(name, kind)
    --[[ Actual instance creation ]]
    local item = {}
    setmetatable(item, Item)
    item.name = name
    item.kind = kind
    return item
end

function Item:load_attribs(kind)
    --[[ Load attributes into self.attribs ]]
    item_table = lib.assload.read('objects/items/', 'json')
    self.attribs = item_table[self.kind]
end

function Item:load_gfx()
    --[[ Load sprite into map ]]
    local texture = MOAITexture.new()
    texture:load('images/items/'..self.attribs.texture..'.png')
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture(texture)
    local w, h = texture:getSize()
    sprite:setRect(-w/32, -h/32, w/32, h/32) -- (w/2) / (16 px/world unit)
    self.prop = MOAIProp2D.new()
    self.prop:setDeck(sprite)
    self.width, self.height = 1, 1
    self.dir_x, self.dir_y = 0, 0
end

function Item:get_cell()
    --[[ Return object's current (i, j) map coordinates ]]
    return map:coords_to_idx(self.prop:getLoc())
end
