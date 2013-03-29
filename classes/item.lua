--[[ Item class ]]

module(..., package.seeall)

Item = {}
Item.__index = Item

function new(name, kind)
    --[[ Instantiate our class and call loading methods ]]
    item = Item.instance(name, kind)
    item:load_gfx()
    item:load_attribs()
    return item
end

function Item.instance(name, kind)
    local item = {}                  -- Build instance
    setmetatable(item, Item)
    item.name = name
    item.kind = kind
    return item
end

function Item:get_name()
    --[[ Return name ]]
    return self.name
end

function Item:load_gfx()
    --[[ Load sprite into map ]]
    local texture = MOAITexture.new()
    print(self.kind)
    if self.kind == 'sword' then
        texture:load('images/items/sword_1.png')
    elseif self.kind == 'key' then
        texture:load('images/items/key_1.png')
    end
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture(texture)
    local w, h = texture:getSize()
    sprite:setRect(-w/32, -h/32, w/32, h/32) -- (w/2) / (16 px/world unit)
    self.prop = MOAIProp2D.new()
    self.prop:setDeck(sprite)
    self.width, self.height = 1, 1
    self.dir_x, self.dir_y = 0, 0
end

function Item:load_attribs()
    --[[ Load attributes into self.attribs ]]
    -- TODO: Load from JSON
    local atr = {}
    if self.kind == 'sword' then
        atr = {
            damage = 5.0, 
            weight = 5.0,
            toughness = 2.0,
            quality = 2.0,
            maneuverability = 5.0,
            intimidation = 6.0
        }
    elseif self.kind == 'key' then
        atr = {
            damage = 0.2, 
            weight = 0.1,
            toughness = 2,
            quality = 2,
            maneuverability = 10,
            intimidation = 0.1
        }
    end
    self.attribs = atr
end


