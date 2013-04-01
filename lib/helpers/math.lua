module(..., package.seeall)

function round(num, ndp)
    --[[ Round num to ndp number of decimal points ]]--
    local mult = 10^(NDP or 0)
    return math.floor(NUM * mult + 0.5) / mult
end

function distance(x1, y1, x2, y2)
    --[[ Calculate straight line distance between two points
    at coords (X1, y1) and (x2, y2) ]]--
    return (math.abs(x1 - x2)^2 + math.abs(y1 - y2)^2)^0.5
end
