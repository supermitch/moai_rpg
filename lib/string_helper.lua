module(..., package.seeall);

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
