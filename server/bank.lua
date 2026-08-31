-- ============================================================================
-- AURA Phone - bank (server)
-- * balance read from getMoney (replace getBalance/setBalance hooks for
--   servers with custom money systems)
-- * server-side transfers: validation, no self-transfer, rate limit,
--   pending credits for offline recipients, audit log
-- ============================================================================
local P = PhoneConfig.database.prefix

-- hooks (override in your own script if you use a custom money system)
function getBalance(player) return getMoney(player) end
function creditMoney(player, amount) setMoney(player, getMoney(player) + amount) end
function debitMoney(player, amount) setMoney(player, getMoney(player) - amount) end

local function toast(player, ok, text)
    triggerClientEvent(player, "phone:toast", player, ok and 1 or 0, text)
end

local function pushBalance(player, txns)
    local pl = Players[player]
    if not pl then return end
    local bal = getBalance(player)
    if txns then
        triggerClientEvent(player, "phone:bank:data", player, bal, txns)
    else
        triggerClientEvent(player, "phone:bank:data", player, bal, nil)
    end
end

local function fetchTxns(player, pl, cb)
    DB.select(string.format(
        "SELECT from_number, to_number, amount, timestamp FROM %sbank_tx "
        .. "WHERE from_number = %s OR to_number = %s ORDER BY timestamp DESC LIMIT 15",
        P, DB.s(pl.number), DB.s(pl.number)), function(ok, rows)
        local out = {}
        for _, r in ipairs(rows or {}) do
            local mineOut = r.from_number == pl.number
            local other = mineOut and r.to_number or r.from_number
            table.insert(out, {
                number = other,
                name = nameForNumber(other),
                out = mineOut,
                amount = r.amount,
                time = r.timestamp,
            })
        end
        cb(out)
    end)
end

-- ---------------------------------------------------------------------------
-- fetch balance + history
-- ---------------------------------------------------------------------------
addEvent("phone:bank:fetch", true)
addEventHandler("phone:bank:fetch", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    fetchTxns(player, pl, function(txns) pushBalance(player, txns) end)
end)

-- ---------------------------------------------------------------------------
-- transfer
-- ---------------------------------------------------------------------------
addEvent("phone:bank:transfer", true)
addEventHandler("phone:bank:transfer", root, function(number, amount)
    local player = client
    local pl = Players[player]
    if not pl then return end
    number = SEC.number(number)
    amount = SEC.amount(amount)
    if not number or not amount then
        toast(player, false, "Invalid number or amount.")
        return
    end
    if number == pl.number then
        toast(player, false, "You cannot transfer to yourself.")
        return
    end
    local targetInfo = NUMBERS[number]
    if not targetInfo then
        toast(player, false, "This number does not exist.")
        SEC.reject(player, "bank transfer to unknown number " .. number, "bank:transfer")
        return
    end
    if not SEC.rate(player, "bank", PhoneConfig.maxTransfersPerHour, 3600) then
        toast(player, false, "Too many transfers, wait a bit.")
        SEC.reject(player, "bank rate limit", "bank:transfer")
        return
    end
    local bal = getBalance(player)
    if amount > bal then
        toast(player, false, "Insufficient balance.")
        return
    end
    debitMoney(player, amount)

    local t = os.time()
    local tname = targetInfo.name
    DB.run(string.format(
        "INSERT INTO %sbank_tx (from_number, to_number, amount, timestamp) VALUES (%s, %s, %d, %d)",
        P, DB.s(pl.number), DB.s(number), amount, t), function()
        phoneNotify(player, "Bank", "Sent $" .. Utils.formatMoney(amount) .. " to " .. tname, "bank")
    end)

    local target = ONLINE[number]
    if target then
        creditMoney(target, amount)
        phoneNotify(target, "Bank", "Received $" .. Utils.formatMoney(amount) .. " from " .. getPlayerName(player), "bank")
    else
        DB.run(string.format(
            "INSERT INTO %sbank_pending (to_number, amount, timestamp) VALUES (%s, %d, %d)",
            P, DB.s(number), amount, t))
        phoneNotify(player, "Bank", "Will be credited when " .. tname .. " logs in.", "bank")
    end

    SEC.audit("TRANSFER", player, "$" .. amount .. " -> " .. number .. " (" .. tname .. ")")
    pushBalance(player, nil)
end)

-- ---------------------------------------------------------------------------
-- apply pending credits on join (called from main.lua finalizeInit flow)
-- ---------------------------------------------------------------------------
function applyPendingCredits(player)
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT id, amount FROM " .. P .. "bank_pending WHERE to_number = " .. DB.s(pl.number), function(ok, rows)
        if not (ok and rows) then return end
        local total = 0
        for _, r in ipairs(rows) do
            total = total + (r.amount or 0)
            DB.run("DELETE FROM " .. P .. "bank_pending WHERE id = " .. DB.i(r.id))
        end
        if total > 0 then
            creditMoney(player, total)
            phoneNotify(player, "Bank", "Received $" .. Utils.formatMoney(total) .. " (offline transfer)", "bank")
            SEC.audit("PENDING_CREDIT", player, "$" .. total)
        end
    end)
end
