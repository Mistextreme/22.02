Database = {}

-- ========================================
-- GET ALL STASHES
-- ========================================

function Database.GetAllStashes(cb)
    MySQL.query('SELECT * FROM unique_stashes ORDER BY created_at DESC', {}, function(result)
        cb(result or {})
    end)
end

-- ========================================
-- GET SINGLE STASH
-- ========================================

function Database.GetStash(stashId, cb)
    MySQL.query('SELECT * FROM unique_stashes WHERE stash_id = ?', { stashId }, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end

-- ========================================
-- CHECK IF STASH EXISTS
-- ========================================

function Database.StashExists(stashId, cb)
    MySQL.query('SELECT id FROM unique_stashes WHERE stash_id = ?', { stashId }, function(result)
        cb(result and #result > 0)
    end)
end

-- ========================================
-- CREATE STASH
-- ========================================

function Database.CreateStash(data, cb)
    MySQL.insert(
        'INSERT INTO unique_stashes (stash_id, label, slots, weight, coords_x, coords_y, coords_z, size_x, size_y, size_z, rotation, code, debug) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.stash_id,
            data.label,
            data.slots,
            data.weight,
            data.coords.x,
            data.coords.y,
            data.coords.z,
            data.size.x,
            data.size.y,
            data.size.z,
            data.rotation or 0.0,
            data.code,
            data.debug and 1 or 0
        },
        function(insertId)
            cb(insertId ~= nil and insertId > 0)
        end
    )
end

-- ========================================
-- UPDATE STASH
-- ========================================

function Database.UpdateStash(data, cb)
    MySQL.update(
        'UPDATE unique_stashes SET label = ?, slots = ?, weight = ?, coords_x = ?, coords_y = ?, coords_z = ?, size_x = ?, size_y = ?, size_z = ?, rotation = ?, code = ?, debug = ? WHERE stash_id = ?',
        {
            data.label,
            data.slots,
            data.weight,
            data.coords.x,
            data.coords.y,
            data.coords.z,
            data.size.x,
            data.size.y,
            data.size.z,
            data.rotation or 0.0,
            data.code,
            data.debug and 1 or 0,
            data.stash_id
        },
        function(rowsChanged)
            cb(rowsChanged > 0)
        end
    )
end

-- ========================================
-- DELETE STASH
-- ========================================

function Database.DeleteStash(stashId, cb)
    MySQL.update('DELETE FROM unique_stashes WHERE stash_id = ?', { stashId }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end
