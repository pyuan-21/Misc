local re2 = require("utility/RE2")
local counter = 0
local f1_pressed = false
local f2_pressed = false
local lock_hitpoint = false
local frequence = 10 -- each N frames to update HP
local god_mode = false

function print_REManagedObject(obj)
    print("=========== start print REManagedObject ================")
    print(obj:get_type_definition():get_full_name())

    local t = obj:get_type_definition()
    for i, m in ipairs(t:get_methods()) do
        print(m:get_name())
    end
    print("=========== end print REManagedObject ================")
end

function dump_hierarchy(obj)
    local td = obj:get_type_definition()

    while td do
        print("===== " .. td:get_full_name() .. " =====")

        for _, m in ipairs(td:get_methods()) do
            print(m:get_name())
        end

        td = td:get_parent_type()
    end
end

function print_fields(obj)
    print("===== PlayerContext fields =====")
    local td = obj:get_type_definition()
    for _, f in ipairs(td:get_fields()) do
        print(f:get_name(), f:get_type():get_full_name())
    end
    print("===============================")
end

function print_components_from_ctx(ctx)
    local comps = ctx:get_Components()

    if comps then
        print("component count:", comps:get_Count())

        for i = 0, comps:get_Count() - 1 do
            local c = comps:get_Item(i)
            if c then
                print(i, c:get_type_definition():get_full_name())
            end
        end
    end
end

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then 
        return nil
    end
    return game_object:call("getComponent(System.Type)", sdk.typeof(type_name))
end

local function get_HitPoint(ctx)
    return get_component(ctx, "app.ropeway.HitPointController")
end

function act_as_god(re2)
    local ctx = re2.get_localplayer()
    if ctx then
        local hp = get_HitPoint(ctx)
        if hp then
            hp:set_Invincible(true)
            hp:set_NoDamage(true)
            hp:set_CurrentHitPoint(hp:get_DefaultHitPoint())
        end
    end
end

function reset_hitpoint(ctx)
    local hp = get_HitPoint(ctx)
    if hp then
        hp:set_CurrentHitPoint(hp:get_DefaultHitPoint())
        -- print("hp update done!")
    end
    -- print(hp)
    -- dump_hierarchy(hp)
    -- print_REManagedObject(hp)
end

function on_lock_hitpoint()
    -- print("[on_lock_hitpoint]")
    local ctx = re2.get_localplayer()
    if ctx then
        reset_hitpoint(ctx)
    end
end

function on_f1_pressed(re2)
    print("[on_f1_pressed]")
    god_mode = not god_mode
    print("god_mode: " .. tostring(god_mode))
end

function on_f2_pressed(re4)
    print("[on_f2_pressed]")
    lock_hitpoint = not lock_hitpoint
    print("lock_hitpoint: " .. tostring(lock_hitpoint))
end

re.on_frame(function()

    counter = (counter + 1 ) % 60

    -- print("counter: " .. tostring(counter))

    -- F1 trigger (edge-safe)
    if not f1_pressed and reframework:is_key_down("0x70") then
        f1_pressed = true
        on_f1_pressed(re2)
    end

    -- F2 trigger (edge-safe)
    if not f2_pressed and reframework:is_key_down("0x71") then
        f2_pressed = true
        on_f2_pressed(re2)
    end

    if counter == 0 then
        f1_pressed = false
        f2_pressed = false
    end

    if counter % frequence == 0 then
        if lock_hitpoint then
            on_lock_hitpoint()
        end
    end

    if god_mode then
        act_as_god(re2)
    end
end)