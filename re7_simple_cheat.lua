local re7 = require("utility/RE7")
local counter = 0
local f1_pressed = false
local f2_pressed = false
local lock_ammo = false
local frequence = 10 -- each N frames to update HP
local auto_fill_remedy = false

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
    -- return get_component(ctx, "app.PlayerDamageController")
    return nil
end

function act_as_god(re7)
    local ctx = re7.get_localplayer()
    if ctx then
        local hp = get_HitPoint(ctx)
        if hp then
            hp:set_Invincible(true)
            hp:set_NoDamage(true)
            hp:set_CurrentHitPoint(hp:get_DefaultHitPoint())
            print("act_as_god!")
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

local function refill_weapon_magazine()
    local ctx = re7.get_localplayer()

    if not ctx then
        return
    end

    local player_gun = get_component(ctx, "app.PlayerGun")

    if not player_gun then
        return
    end

    local weapon = player_gun:get_field("WeaponGun")

    if not weapon then
        return
    end

    weapon:set_loadNum(weapon:get_maxLoadNum())
    -- print("refill_weapon_magazine")
end

function on_lock_ammo()
    -- print("[on_lock_ammo]")
    refill_weapon_magazine()
end

function on_f1_pressed(re7)
    print("[on_f1_pressed]")
    lock_ammo = not lock_ammo
    print("lock_ammo: " .. tostring(lock_ammo))
end

-- RemedyM
local function FindItemObjs(item_name_key)
    local item_obj_list = {}
    local ctx = re7.get_localplayer()
    if not ctx then return item_obj_list end

    local inventory = get_component(ctx, "app.Inventory")
    if not inventory then return item_obj_list end

    local item_list = inventory:call("get_ItemList")

    for i = 0, item_list:get_Count() - 1 do
        local item_info = item_list:get_Item(i)

        if item_info then
            local item_obj = item_info:get_field("Item")

            if item_obj then
                local item_data = item_obj:call("get_ItemData")

                if item_data then
                    local item_dataID = item_data:get_field("ItemDataID")

                    if string.find(item_dataID, item_name_key, 1, true) then
                        -- print("Found:", item_dataID)
                        table.insert(item_obj_list, item_obj)
                    end
                end
            end
        end
    end
    return item_obj_list
end

-- will just set the StackNum for items.
function refill_item(item_name_key)
    local item_obj_list = FindItemObjs(item_name_key)
    for i, item_obj in ipairs(item_obj_list) do
        -- print("ItemDataID:", item_obj:get_field("ItemDataID"))
        -- print("StackNum:", item_obj:call("getStackNum"))
        -- print("MaxStackNum:", item_obj:call("getMaxStackNum"))
        item_obj:setStackNum(item_obj:getMaxStackNum())
        -- print("refill_item", item_obj:get_field("ItemDataID"))
    end
end

function on_f2_pressed(re7)
    print("[on_f2_pressed]")
    auto_fill_remedy = not auto_fill_remedy
    print("auto_fill_remedy: " .. tostring(auto_fill_remedy))
end

re.on_frame(function()

    counter = (counter + 1 ) % 60

    -- print("counter: " .. tostring(counter))

    -- F1 trigger (edge-safe)
    if not f1_pressed and reframework:is_key_down("0x70") then
        f1_pressed = true
        on_f1_pressed(re7)
    end

    -- F2 trigger (edge-safe)
    if not f2_pressed and reframework:is_key_down("0x71") then
        f2_pressed = true
        on_f2_pressed(re7)
    end

    if counter == 0 then
        f1_pressed = false
        f2_pressed = false
    end

    if counter % frequence == 0 then
        if lock_ammo then
            on_lock_ammo()
        end
        if auto_fill_remedy then
            refill_item("Remedy")
        end
    end
end)