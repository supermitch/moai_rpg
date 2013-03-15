--[[ Rectangle shape class ]]--

module(..., package.seeall)

Rectangle = {}
Rectangle.__index = Rectangle

function Rectangle.new(left, top, right, bottom)
    local rect = {}
    setmetatable(rect, Rectangle)
    rect.left = left or 0
    rect.top = top or 0
    rect.right = right
    rect.bottom = bottom
    rect.width = math.abs(rect.right - rect.left)
    rect.height = math.abs(rect.top - rect.bottom)
    return rect
end

function Rectangle:get_size()
    -- Return width & height
    return self.width, self.height
end

function Rectangle:get_edges()
    -- Return the left, top, right and bottom values
    return self.left, self.top, self.right, self.bottom
end

function Rectangle:collide_point(x, y)
    --[[ Determine if point (x, y) is inside the rectangle. ]]--
    if self.left < x and self.right > x then
        if self.top < y and self.bottom > y then
            return true
        end
    end
    return false
end
