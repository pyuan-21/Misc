local re4 = require("utility/RE4")
local god_mode = true

local counter = 0
local f1_pressed = false
local f2_pressed = false
local f3_pressed = false
local ignore_dmg = false
local ignore_all_dmg = false -- including enemy, only set it to true when it is final scene(escaping via boat)

local hit = sdk.find_type_definition("chainsaw.HitController")

local function test_func(args)
    local atk_data = sdk.to_managed_object(args[5])
    if atk_data then
        print("print atk_data...")
        print_REManagedObject(atk_data)

        local con1 = atk_data:get_HasAttackToPlayerData()
        local con2 = atk_data:get_HasAttackToEnemyData()
        local con3 = atk_data:get_AttackType()

        -- damage from floating-trash on the lake: con1[true], con2[false], con3[10]

        print("get_HasAttackToPlayerData:", atk_data:get_HasAttackToPlayerData())
        print("get_HasAttackToEnemyData:", atk_data:get_HasAttackToEnemyData())
        print("get_AttackType:", atk_data:get_AttackType())
    end
end

local function block_damage(args)
    if ignore_all_dmg then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end

    -- test_func(args)
    -- print("[block_damage] ignore_dmg: ", ignore_dmg)
    if ignore_dmg then
        local atk_data = sdk.to_managed_object(args[5])
        -- print("[block_damage] atk_data: ", atk_data)
        if atk_data then
            local con1 = atk_data:get_HasAttackToPlayerData()
            local con2 = atk_data:get_HasAttackToEnemyData()
            local con3 = atk_data:get_AttackType()
            
            print("con1:", con1, "con2:", con2, "con3:", con3)

            -- damage from floating-trash on the lake: con1[true], con2[false], con3[10]
            if con1 and not con2 and con3 == 10 then
                -- print("should be invincible")
                return sdk.PreHookResult.SKIP_ORIGINAL
            end

            -- damage from mine-cart on the rail: con1[false], con2[true], con3[0]
            if not con1 and con2 and con3 == 0 then
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
            -- damage from enemies on the rail: con1[true], con2[false], con3[8]
            if con1 and not con2 and con3 == 8 then
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
            -- damage from chainsaw man on the rail: con1[true], con2[false], con3[2]
            if con1 and not con2 and con3 == 2 then
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end
end

sdk.hook(
    hit:get_method("callbackDamageHit"),
    block_damage,
    function(retval) return retval end
)

sdk.hook(
    hit:get_method("callbackAttackHit"),
    block_damage,
    function(retval) return retval end
)

function print_REManagedObject(obj)
    print("=========== start print REManagedObject ================")
    print(obj:get_type_definition():get_full_name())

    local t = obj:get_type_definition()
    for i, m in ipairs(t:get_methods()) do
        print(m:get_name())
    end
    print("=========== end print REManagedObject ================")
end

function act_as_god(re4)
    local ctx = re4.get_localplayer_ctx()
    if ctx then
        -- God Mode flag
        ctx:set_IsInvincible(true)

        -- optional safety HP lock
        local hp = ctx:get_HitPoint()
        if hp then
            hp:set_Invincible(true)
            hp:set_NoDamage(true)
            hp:set_NoDeath(true)
            hp:set_Immortal(true)
            hp:set_CurrentHitPoint(hp:get_DefaultHitPoint())
            -- print("hp", hp)
            -- print_REManagedObject(hp)
        end
    end
end

function set_enemies_weak(re4)
    local character_manager = sdk.get_managed_singleton(sdk.game_namespace("CharacterManager"))
    if character_manager then
        local enemy_list = character_manager:get_EnemyContextList()
        if enemy_list then
            local count = enemy_list:get_Count()
            if count then
                for i = 0, count - 1 do
                    local enemy = enemy_list:get_Item(i)
                    if enemy then
                        local hp = enemy:get_HitPoint()
                        if hp then
                            local isDead = hp:get_IsDead()
                            if not isDead then
                                hp:set_CurrentHitPoint(1)
                                -- print("successfully set enemy at index [" .. tostring(i) .. "] to weak!")
                            end
                        end
                    end
                end
            end
        end
    end
end

function on_f1_pressed(re4)
    -- print("[on_f1_pressed]")
    ignore_dmg = not ignore_dmg
    print("ignore_dmg:", ignore_dmg)
end

function on_f2_pressed(re4)
    -- print("[on_f2_pressed]")
    ignore_all_dmg = not ignore_all_dmg
    print("ignore_all_dmg:", ignore_all_dmg)
end

function on_f3_pressed(re4)
    print("[on_f3_pressed]")
    set_enemies_weak(re4)
end

re.on_frame(function()
    if god_mode then
        act_as_god(re4)
    end

    counter = (counter + 1 ) % 60

    -- F1 trigger (edge-safe)
    if not f1_pressed and reframework:is_key_down("0x70") then
        f1_pressed = true
        on_f1_pressed(re4)
    end

    -- F2 trigger (edge-safe)
    if not f2_pressed and reframework:is_key_down("0x71") then
        f2_pressed = true
        on_f2_pressed(re4)
    end

    -- F3 trigger
    if not f3_pressed and reframework:is_key_down("0x72") then
        f3_pressed = true
        on_f3_pressed(re4)
    end

    if counter == 0 then
        f1_pressed = false
        f2_pressed = false
        f3_pressed = false
    end
end)
