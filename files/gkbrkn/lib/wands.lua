dofile_once( "data/scripts/gun/procedural/gun_procedural.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua" );

local WAND_STAT_SETTER = {
    Direct = 1,
    Gun = 2,
    GunAction = 3
}

local WAND_STAT_SETTERS = {
    shuffle_deck_when_empty = WAND_STAT_SETTER.Gun,
    actions_per_round = WAND_STAT_SETTER.Gun,
    speed_multiplier = WAND_STAT_SETTER.GunAction,
    deck_capacity = WAND_STAT_SETTER.Gun,
    reload_time = WAND_STAT_SETTER.Gun,
    fire_rate_wait = WAND_STAT_SETTER.GunAction,
    spread_degrees = WAND_STAT_SETTER.GunAction,
    mana_charge_speed = WAND_STAT_SETTER.Direct,
    mana_max = WAND_STAT_SETTER.Direct,
    mana = WAND_STAT_SETTER.Direct,
}

function ability_component_get_stat( ability, stat )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        if setter == WAND_STAT_SETTER.Direct then
            return ComponentGetValue( ability, stat );
        elseif setter == WAND_STAT_SETTER.Gun then
            return ComponentObjectGetValue( ability, "gun_config", stat );
        elseif setter == WAND_STAT_SETTER.GunAction then
            return ComponentObjectGetValue( ability, "gunaction_config", stat );
        end
    end
end

function ability_component_set_stat( ability, stat, value )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        if setter == WAND_STAT_SETTER.Direct then
            ComponentSetValue( ability, stat, tostring( value ) );
        elseif setter == WAND_STAT_SETTER.Gun then
            ComponentObjectSetValue( ability, "gun_config", stat, tostring( value ) );
        elseif setter == WAND_STAT_SETTER.GunAction then
            ComponentObjectSetValue( ability, "gunaction_config", stat, tostring( value ) );
        end
    end
end

function ability_component_adjust_stat( ability, stat, callback )
    local setter = WAND_STAT_SETTERS[stat];
    if setter ~= nil then
        local current_value = nil;
        if setter == WAND_STAT_SETTER.Direct then
            current_value = ComponentGetValue( ability, stat );
        elseif setter == WAND_STAT_SETTER.Gun then
            current_value = ComponentObjectGetValue( ability, "gun_config", stat );
        elseif setter == WAND_STAT_SETTER.GunAction then
            current_value = ComponentObjectGetValue( ability, "gunaction_config", stat );
        end
        local new_value = callback( current_value );
        if setter == WAND_STAT_SETTER.Direct then
            ComponentSetValue( ability, stat, tostring( new_value ) );
        elseif setter == WAND_STAT_SETTER.Gun then
            ComponentObjectSetValue( ability, "gun_config", stat, tostring( new_value ) );
        elseif setter == WAND_STAT_SETTER.GunAction then
            ComponentObjectSetValue( ability, "gunaction_config", stat, tostring( new_value ) );
        end
    end
end

function ability_component_set_stats( ability, stat_value_table )
    for stat,value in pairs(stat_value_table) do
        ability_component_set_stat( ability, stat, value );
    end
end

function ability_component_adjust_stats( ability, stat_callback_table )
    for stat,callback in pairs(stat_callback_table) do
        ability_component_adjust_stat( ability, stat, callback );
    end
end

function initialize_wand( wand, wand_data )
    local ability = EntityGetFirstComponent( wand, "AbilityComponent" );
    if wand_data.name ~= nil then
        ComponentSetValue( ability, "ui_name", wand_data.name );
    end

    local item = EntityGetFirstComponent( wand, "ItemComponent" );
    if item ~= nil then
        ComponentSetValue( item, "item_name", wand_data.name );
    end

    for stat,value in pairs( wand_data.stats or {} ) do
        ability_component_set_stat( ability, stat, value );
    end

    for stat,range in pairs( wand_data.stat_ranges or {} ) do
        ability_component_set_stat( ability, stat, Random( range[1], range[2] ) );
    end

    for stat,random_values in pairs( wand_data.stat_randoms or {} ) do
        ability_component_set_stat( ability, stat, random_values[ Random( 1, #random_values ) ] );
    end

    ability_component_set_stat( ability, "mana", ability_component_get_stat( ability, "mana_max" ) );

    for _,actions in pairs( wand_data.permanent_actions or {} ) do
        local random_action = actions[ Random( 1, #actions ) ];
        if random_action ~= nil then
            AddGunActionPermanent( wand, random_action );
        end
    end

    --for _,actions in pairs( wand_data.actions or {} ) do
    if wand_data.actions then
        for action_index=1,#wand_data.actions,1 do
            local actions = wand_data.actions[action_index];
            if actions ~= nil then
                local random_action = actions[ Random( 1, #actions ) ];
                if random_action ~= nil then
                    if type( random_action ) == "table" then
                        local amount = random_action.amount or 1;
                        for _=1,amount,1 do
                            local action_entity = CreateItemActionEntity( random_action.action );
                            if action_entity then
                                local item = FindFirstComponentByType( action_entity, "ItemComponent" );
                                if random_action.locked then
                                    ComponentSetValue( item, "is_frozen", "1" );
                                end
                                if random_action.permanent then
                                    ComponentSetValue( item, "permanently_attached", "1" );
                                end
                                ComponentSetValue2( item, "inventory_slot", action_index - 1, 0 );
                                EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
                                EntityAddChild( wand, action_entity );
                            end
                        end
                    else
                        local action_entity = CreateItemActionEntity( random_action );
                        if action_entity then
                            local item = FindFirstComponentByType( action_entity, "ItemComponent" );
                            if item ~= nil then
                                ComponentSetValue2( item, "inventory_slot", action_index - 1, 0 );
                            end
                            EntitySetComponentsWithTagEnabled( action_entity, "enabled_in_world", false );
                            EntityAddChild( wand, action_entity );
                            --AddGunAction( wand, random_action );
                        end
                    end
                end
            end
        end
    end
    
    if wand_data.sprite ~= nil then
        if wand_data.sprite.file ~= nil then
            ComponentSetValue( ability, "sprite_file", wand_data.sprite.file );
            -- TODO this takes a second to apply, probably worth fixing, but for now just prefer using custom file
            local sprite = EntityGetFirstComponent( wand, "SpriteComponent", "item" );
            if sprite ~= nil then
                ComponentSetValue( sprite, "image_file", wand_data.sprite.file );
            end
        end
        if wand_data.sprite.hotspot ~= nil then
            local hotspot = EntityGetFirstComponent( wand, "HotspotComponent", "shoot_pos" );
            if hotspot ~= nil then
                ComponentSetValueVector2( hotspot, "offset", wand_data.sprite.hotspot.x, wand_data.sprite.hotspot.y );
            end
        end
    else
        local gun = {
            deck_capacity = ability_component_get_stat( ability, "deck_capacity" ),
            actions_per_round = ability_component_get_stat( ability,"actions_per_round" ),
            reload_time = ability_component_get_stat( ability,"reload_time" ),
            shuffle_deck_when_empty = ability_component_get_stat( ability,"shuffle_deck_when_empty" ),
            fire_rate_wait = ability_component_get_stat( ability,"fire_rate_wait" ),
            spread_degrees = ability_component_get_stat( ability,"spread_degrees" ),
            speed_multiplier = ability_component_get_stat( ability,"speed_multiplier" ),
            mana_charge_speed = ability_component_get_stat( ability,"mana_charge_speed" ),
            mana_max = ability_component_get_stat( ability,"mana_max" ),
        };
        local dynamic_wand = GetWand( gun );
        SetWandSprite( wand, ability, dynamic_wand.file, dynamic_wand.grip_x, dynamic_wand.grip_y, ( dynamic_wand.tip_x - dynamic_wand.grip_x ), ( dynamic_wand.tip_y - dynamic_wand.grip_y ) );
    end

    if wand_data.callback ~= nil then
        wand_data.callback( wand, ability );
    end
end


function wand_explode_random_action( wand, include_permanent_actions, include_frozen_actions, ox, oy )
    local x, y = EntityGetTransform( wand );
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for i,action in ipairs( children ) do
        local item_action = FindFirstComponentByType( action, "ItemActionComponent" );
        if item_action ~= nil then
            local item = FindFirstComponentByType( action, "ItemComponent" );
            if item ~= nil then
                local action_id = ComponentGetValue( item_action, "action_id" );
                if action_id ~= nil then
                    if include_permanent_actions == true or ComponentGetValue( item, "permanently_attached" ) == "0" then
                        if include_frozen_actions == true or ComponentGetValue( item, "is_frozen" ) == "0" then
                            table.insert( actions, { action_id=action_id, permanent=permanent, entity=action } );
                        end
                    end
                end
            end
        end
    end
    if #actions > 0 then
        local r = math.ceil( math.random() * #actions );
        local action_to_remove = actions[ r ];
        local card = CreateItemActionEntity( action_to_remove.action_id, ox or x, oy or y );
        ComponentSetValueVector2( EntityGetFirstComponent( card, "VelocityComponent" ), "mVelocity", Random( -150, 150 ), Random( -250, -100 ) );
        EntityRemoveFromParent( action_to_remove.entity );
        return action_to_remove;
    end
end

function wand_remove_first_action( wand, include_permanent_actions, include_frozen_actions )
    local x, y = EntityGetTransform( wand );
    local actions = {};
    local children = EntityGetAllChildren( wand ) or {};
    for _,action in pairs( children ) do
        local item_action = FindFirstComponentByType( action, "ItemActionComponent" );
        if item_action ~= nil then
            local item = FindFirstComponentByType( action, "ItemComponent" );
            if item ~= nil then
                if include_permanent_actions == true or ComponentGetValue( item, "permanently_attached" ) == "0" then
                    if include_frozen_actions == true or ComponentGetValue( item, "is_frozen" ) == "0" then
                        EntityRemoveFromParent( action );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_world", true );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_hand", false );
                        EntitySetComponentsWithTagEnabled( action,  "enabled_in_inventory", false );
                        EntitySetComponentsWithTagEnabled( action,  "item_unidentified", false );
                        EntitySetTransform( action, x, y );
                        return action;
                    end
                end
            end
        end
    end
end

function wand_lock( wand, lock_spells, lock_wand )
    if lock_spells == nil then lock_spells = true; end
    if lock_wand == nil then lock_wand = true; end
    if lock_spells then
        local children = EntityGetAllChildren( wand ) or {};
        for i,action in ipairs( children ) do
            local item = FindFirstComponentByType( action, "ItemComponent" );
            if item ~= nil then
                ComponentSetValue( item, "is_frozen", "1" );
            end
        end
    end
    if lock_wand then
        local item = FindFirstComponentByType( wand, "ItemComponent" );
        if item ~= nil then
            ComponentSetValue( item, "is_frozen", "1" );
        end
    end
end

function wand_attach_action( wand, action, permanent, locked )
    EntityAddChild( wand, action );
    local item_action = FindFirstComponentByType( action, "ItemActionComponent" );
    if item_action ~= nil then
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_world", false );
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_hand", false );
        EntitySetComponentsWithTagEnabled( action,  "enabled_in_inventory", false );
    end
end

function wand_is_special( wand )
    if EntityGetVariableNumber( wand, "gkbrkn_challenge_wand", 0 ) == 1
    or EntityGetVariableNumber( wand, "gkbrkn_duplicate_wand", 0 ) == 1
    or EntityGetVariableNumber( wand, "gkbrkn_legendary_wand", 0 ) == 1
    or EntityGetVariableNumber( wand, "gkbrkn_loadout_wand", 0 ) == 1
    or EntityGetVariableNumber( wand, "gkbrkn_merge_wand", 0 ) == 1
    then
        return true;
    end
end

function wand_is_always_cast_valid( wand )
    local children = EntityGetAllChildren( wand ) or {};
    for i,v in ipairs( children ) do
        local components = EntityGetAllComponents( v );
        local has_a_valid_spell = false;
        for _,component in pairs(components) do
            if ComponentGetValue( component, "permanently_attached" ) == "0" then
                has_a_valid_spell = true;
                break;
            end
        end
        if has_a_valid_spell then
            return true;
        end
    end
    return false;
end

function force_always_cast( wand, amount )
    if amount == nil then amount = 1 end
    local children = EntityGetAllChildren( wand ) or {};
    local always_cast_count = 0;
    for _,child in pairs( children ) do
        local item_component = FindFirstComponentByType( child, "ItemComponent" );
        if item_component then
            if ComponentGetValue( item_component, "permanently_attached" ) == "1" then
                always_cast_count = always_cast_count + 1;
                break;
            end
        end
    end
    while always_cast_count < amount do
        local random_child = children[ Random( 1,#children ) ];
        local item_component = FindFirstComponentByType( random_child, "ItemComponent" );
        if item_component and ComponentGetValue( item_component, "permanently_attached" ) ~= "1" then
            ComponentSetValue( item_component, "permanently_attached", "1" );
            always_cast_count = always_cast_count + 1;
        end
    end
end

function initialize_legendary_wand( base_wand, x, y, level, force )
    dofile( "mods/gkbrkn_noita/files/gkbrkn/content/legendary_wands.lua" );
    for _,child in pairs( EntityGetAllChildren( base_wand ) or {} ) do
        EntityRemoveFromParent( child );
    end
    local shine = EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/legendary_wands/legendary_wand_shine.xml" );
    if shine ~= nil then
        EntityAddChild( base_wand, shine );
    end
    SetRandomSeed( GameGetFrameNum(), x + y );
    local valid_wands = {};
    local chosen_wand = force;
    local content_data = nil;
    if chosen_wand == nil then
        for index,content in pairs( legendary_wands ) do
            if (level == nil or ( level >= content.min_level or 0 and level <= content.max_level or 99 ) ) then
                table.insert( valid_wands, index );
            end
        end
        chosen_wand = valid_wands[Random( 1, #valid_wands )];
    end
    content_data = force or legendary_wands[chosen_wand];
    if content_data == nil then print("[goki's things] legendary wand error: no wand data found"); return; end
    initialize_wand( base_wand, content_data.wand );
end