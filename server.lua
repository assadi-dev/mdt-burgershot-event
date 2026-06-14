local QBCore = exports['qb-core']:GetCoreObject()
local Config = lib.require('config')

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function send(res, code, payload)
    res.writeHead(code)
    res.send(json.encode(payload))
end

-- Returns an array of player sources for the burgershot job.
local function getBurgerPlayers(onDutyOnly)
    return QBCore.Functions.GetPlayersByJob('burgershot', onDutyOnly)
end

local function parseQuery(queryStr)
    local params = {}
    for k, v in (queryStr or ''):gmatch('([^&=]+)=([^&=]*)') do
        params[k] = v
    end
    return params
end

local function parseQuery(queryStr)
    local params = {}
    for k, v in (queryStr or ''):gmatch('([^&=]+)=([^&=]*)') do
        params[k] = v
    end
    return params
end

-- ─── Auth middleware ──────────────────────────────────────────────────────────

local function getHeader(headers, name)
    if not headers then return nil end
    local lower = name:lower()
    for k, v in pairs(headers) do
        if k:lower() == lower then return v end
    end
end

local function checkSecret(req, res)
    local secret = getHeader(req.headers, 'x-secret')
    if not secret then
        send(res, 401, {message = 'Unauthorized: missing x-secret header'}) ; return false
    end
    if secret ~= Config.WebhookSecret then
        send(res, 403, {message = 'Forbidden: invalid x-secret'}) ; return false
    end
    return true
end

-- ─── Route handlers ───────────────────────────────────────────────────────────

-- POST /notify  body: { title?, message }
local function routeNotify(data, res)
    local title   = tostring(data.title   or Config.NotifyTitle)
    local message = tostring(data.message or '')

    if message == '' then
        send(res, 400, {message = 'Missing field: message'}) ; return
    end

    local targets = getBurgerPlayers(true)
    for _, src in ipairs(targets) do
        TriggerClientEvent('mdt-burgershot-event:client:notify', src, title, message)
    end

    send(res, 200, {ok = true, notified = #targets})
end

-- POST /announce  body: { title?, message }
local function routeAnnounce(data, res)
    local title   = tostring(data.title   or Config.NotifyTitle)
    local message = tostring(data.message or '')

    if message == '' then
        send(res, 400, {message = 'Missing field: message'}) ; return
    end

    local targets = getBurgerPlayers(true)
    for _, src in ipairs(targets) do
        TriggerClientEvent('mdt-burgershot-event:client:announce', src, title, message)
    end

    send(res, 200, {ok = true, announced = #targets})
end

-- POST /duty  body: { citizenid, duty? }
local function routeDuty(data, res)
    local citizenid = data.citizenid
    if not citizenid or citizenid == '' then
        send(res, 400, {message = 'Missing field: citizenid'}) ; return
    end

    local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not player then
        send(res, 404, {message = 'Player not found or offline'}) ; return
    end

    if player.PlayerData.job.name ~= 'burgershot' then
        send(res, 403, {message = 'Player is not a burgershot employee'}) ; return
    end

    local currentDuty = player.PlayerData.job.onduty
    local newDuty     = (data.duty ~= nil) and data.duty or (not currentDuty)

    player.Functions.SetJobDuty(newDuty)

    local label = newDuty and 'Prise de service' or 'Fin de service'
    TriggerClientEvent('mdt-burgershot-event:client:notify', player.PlayerData.source, Config.NotifyTitle, label)

    send(res, 200, {ok = true, citizenid = citizenid, onduty = newDuty})
end

-- POST /duty/status  body: { citizenid }
local function routeDutyStatus(data, res)
    local citizenid = data.citizenid
    if not citizenid or citizenid == '' then
        send(res, 400, {message = 'Missing field: citizenid'}) ; return
    end

    local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not player then
        send(res, 404, {message = 'Player not found or offline'}) ; return
    end

    if player.PlayerData.job.name ~= 'burgershot' then
        send(res, 403, {message = 'Player is not a burgershot employee'}) ; return
    end

    send(res, 200, {citizenid = citizenid, onduty = player.PlayerData.job.onduty})
end

-- ─── Router ───────────────────────────────────────────────────────────────────

local routes = {
    ['POST:' .. Config.WebhookPath]             = { fn = routeNotify,      body = true  },
    ['POST:' .. Config.WebhookPathAnnounce]     = { fn = routeAnnounce,    body = true  },
    ['POST:' .. Config.WebhookPathDutyPath]     = { fn = routeDuty,        body = true  },
    ['POST:' .. Config.WebhookPathDutyStatus]   = { fn = routeDutyStatus,  body = true  },
}

SetHttpHandler(function(req, res)
    local basePath, queryStr = req.path:match('^([^?]*)%??(.*)')
    print('[mdt-burgershot-event] HTTP ' .. req.method .. ' path=' .. tostring(basePath))

    local route = routes[req.method .. ':' .. basePath]
    if not route then
        send(res, 404, {message = 'Not Found'}) ; return
    end

    if not checkSecret(req, res) then return end

    if not route.body then
        route.fn(parseQuery(queryStr), res)
        return
    end

    req.setDataHandler(function(body)
        if not body or body == '' then
            send(res, 400, {message = 'Empty body'}) ; return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then
            send(res, 400, {message = 'Invalid JSON'}) ; return
        end

        route.fn(data, res)
    end)
end)
