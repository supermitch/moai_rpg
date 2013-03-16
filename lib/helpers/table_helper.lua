module(..., package.seeall)

function is_in(value, table)
    -- Return true if value is in table values
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return nil
end
