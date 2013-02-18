module(..., package.seeall);

function round(num, idp)
    -- Round to idp number of decimal points
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function distance(X1, Y1, X2, Y2)
    -- Calculate straight line distance between two points
    return (math.abs(X1 - X2)^2 + math.abs(Y1 - Y2)^2)^0.5
end
