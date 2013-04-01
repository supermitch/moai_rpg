module(..., package.seeall)

function round(number, decimals)
    --[[ Round 'number' to 'decimals' number of decimal points ]]--
    local multiplier = 10^(decimals or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function distance(x1, y1, x2, y2)
    --[[ Calculate straight line distance between two points
    at coords (X1, y1) and (x2, y2) ]]--
    return (math.abs(x1 - x2)^2 + math.abs(y1 - y2)^2)^0.5
end
