local lock_hitpoint = false
local counter = 0
local f1_pressed = false
local f2_pressed = false
local frequence = 10 -- each N frames to update HP

log.info("------------------------------------------")
log.warn("------------------------------------------")
log.error("------------------------------------------")

function log_REManagedObject(obj)
    log.info("=========== start print REManagedObject ================")
    log.info(obj:get_type_definition():get_full_name())

    local t = obj:get_type_definition()
    for i, m in ipairs(t:get_methods()) do
        log.info(m:get_name())
    end
    log.info("=========== end print REManagedObject ================")
end

function log_charactermanager_all()
    local td = sdk.find_type_definition("app.CharacterManager")

    if td then
        log.info("===== app.CharacterManager ALL METHODS =====")

        for _, m in ipairs(td:get_methods()) do
            log.info(m:get_name())
        end

        log.info("=========================================")
    end
end

function log_playercontext_all()
    local td = sdk.find_type_definition("app.PlayerContext")

    if td then
        log.info("===== app.PlayerContext ALL METHODS =====")

        for _, m in ipairs(td:get_methods()) do
            log.info(m:get_name())
        end

        log.info("=========================================")
    end
end

function log_hitpoint_all()
    local td = sdk.find_type_definition("app.HitPoint")

    if td then
        log.info("===== app.HitPoint methods =====")

        for _, m in ipairs(td:get_methods()) do
            log.info(m:get_name())
        end

        log.info("================================")
    else
        log.info("app.HitPoint not found")
    end
end

function get_player_ctx()
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if cm then
        local list = cm:call("get_PlayerContextList")
        local size = list:call("get_Count")
        if size and size == 1 then
            local ctx = list:call("get_Item", 0)
            return ctx
        end
    end
end

function update_hitpoint(ctx, value)
    local hp = ctx:get_HitPoint()
    if hp then
        hp:set_CurrentHitPoint(value)
    end
end

function on_lock_hitpoint()
	local ctx = get_player_ctx()
    if ctx then
        update_hitpoint(ctx, 2000)
        -- log.info("[Player HP updated!]")
    end
end

function log_playercontext_fields(ctx)

    log.info("===== PlayerContext fields =====")

    local td = ctx:get_type_definition()

    for _, f in ipairs(td:get_fields()) do
        log.info(f:get_name())
    end

    log.info("===============================")

end

function on_log_ctx(ctx)
    -- log_REManagedObject(ctx)
    local hp = ctx:get_HitPoint()
    if hp then
        -- hp:set_Invincible(true)
        -- hp:set_NoDamage()
        -- hp:set_NoDeath()
        hp:set_CurrentHitPoint(2000)
    else
        log.info("hp is nil")
    end

    -- ctx:call("updateHitPointVital")
end

function log_playerequipment_methods()
    local td = sdk.find_type_definition("app.PlayerEquipment")

    if td then
        for _,m in ipairs(td:get_methods()) do
            log.info(m:get_name())
        end
    else
        log.info("it is nil")
    end
end

-- PlayerContext inherits from CharacterContext. This function to log all inherited classes's methods.
function dump_hierarchy(obj)
    local td = obj:get_type_definition()

    while td do
        log.info("===== " .. td:get_full_name() .. " =====")

        for _, m in ipairs(td:get_methods()) do
            log.info(m:get_name())
        end

        td = td:get_parent_type()
    end
end

function log_enemies()
    log.info("[log_enemies]")
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if cm then
        local list = cm:call("get_EnemyContextList")
        local size = list:call("get_Count")
        if size then
            log.info("enemies size: " .. tostring(size))
        end
    end
end

function on_f1_pressed()
	log.info("[on_f1_pressed]")
    log.info("lock_hitpoint: " .. tostring(lock_hitpoint))
    lock_hitpoint = not lock_hitpoint
end

function set_enemies_to_weak()
    local cm = sdk.get_managed_singleton("app.CharacterManager")
    if cm then
        local list = cm:call("get_EnemyContextList")
        local size = list:call("get_Count")
        if size then
            -- log.info("enemies size: " .. tostring(size))
            for i = 0, size - 1 do
                local ctx = list:call("get_Item", i)
                -- log.info("Enmey hitpoint at index: " .. tostring(i) .. ", isDead: " .. tostring(ctx:get_IsDead()))
                if ctx and not ctx:get_IsDead() then
                    update_hitpoint(ctx, 1)
                    -- log.info("successfully update enmey hitpoint at index: " .. tostring(i))
                end
            end
        end
    end
end

function on_f2_pressed()
    log.info("[on_f2_pressed]")
    set_enemies_to_weak()
end

re.on_frame(function()
    counter = (counter + 1 ) % 60

    -- F1 trigger (edge-safe)
    if not f1_pressed and reframework:is_key_down("0x70") then
        f1_pressed = true
        on_f1_pressed()
    end

    -- F2 trigger (edge-safe)
    if not f2_pressed and reframework:is_key_down("0x71") then
        f2_pressed = true
        on_f2_pressed()
    end

    if counter == 0 then
        f1_pressed = false
        f2_pressed= false
    end

    if counter % frequence == 0 then
        if lock_hitpoint then
            on_lock_hitpoint()
        end
    end
end)