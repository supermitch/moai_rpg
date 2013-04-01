module(..., package.seeall);

function firstToUpper(str)
    --[[ Capitalize first letter of str. ]]--
    return (str:gsub("^%l", string.upper))
end
