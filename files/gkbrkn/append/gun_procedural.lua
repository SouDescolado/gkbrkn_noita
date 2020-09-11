dofile_once( "data/scripts/gun/gun_enums.lua" );
local MISC = dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/options.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/flags.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/wands.lua" );

local extended_types = {
    ACTION_TYPE_STATIC_PROJECTILE,
    ACTION_TYPE_MATERIAL,
    ACTION_TYPE_OTHER,
    ACTION_TYPE_UTILITY,
    ACTION_TYPE_PASSIVE
};
local chance_to_replace = 0.03;
local _generate_gun = generate_gun;
function generate_gun( cost, level, force_unshuffle )
    _generate_gun( cost, level, force_unshuffle );
    local entity = GetUpdatedEntityID();
    local x,y = EntityGetTransform( entity );
    local local_wands = EntityGetInRadiusWithTag( x, y, 1, "wand" ) or {};
    local players = EntityGetWithTag("player_unit") or {};
    local wandsmith_stacks = 0;
    local mana_mastery_stacks = 0;
    for _,player in pairs( players ) do
        wandsmith_stacks = wandsmith_stacks + EntityGetVariableNumber( player, "gkbrkn_wandsmith_stacks", 0 );
        mana_mastery_stacks = mana_mastery_stacks + EntityGetVariableNumber( player, "gkbrkn_mana_mastery", 0 );
    end

    for _,wand in pairs( local_wands ) do
        local ability = FindFirstComponentByType( wand, "AbilityComponent" );
        if HasFlagPersistent( MISC.ChaoticWandGeneration.EnabledFlag ) then
            local children = EntityGetAllChildren( wand );
            for _,child in ipairs( children ) do
                local item = FindFirstComponentByType( child, "ItemComponent" );
                local permanent_action = false;
                if item ~= nil then
                    if ComponentGetValue( item, "permanently_attached" ) == "1" then
                        permanent_action = true;
                    end
                end
                EntityRemoveFromParent( child );
                local child_to_return = child;
                local components = EntityGetAllComponents( child );
                for _, component in ipairs( components ) do
                    local action_id = ComponentGetValue( component, "action_id" );
                    if action_id ~= nil and action_id ~= "" then
                        -- TODO an assert will fail if the action type pool is empty
                        -- not too much that can be done about this right now, doesn't show up outside of dev
                        local action = GetRandomActionWithType( x, y, level or Random(0,6), Random(0,7), Random(0,1000)+_+x+y );
                        if action ~= nil and action ~= "" then
                            child_to_return = CreateItemActionEntity( action, x, y );
                            local item = EntityGetFirstComponent( child_to_return, "ItemComponent" );
                            if item ~= nil then
                                if permanent_action == true  then
                                    ComponentSetValue( item, "permanently_attached", "1" );
                                end
                            end
                            EntitySetComponentsWithTagEnabled( child_to_return, "enabled_in_world", false );
                        end
                    end
                end
                EntityAddChild( wand, child_to_return );
            end
        elseif HasFlagPersistent( MISC.ExtendedWandGeneration.EnabledFlag ) then
            local children = EntityGetAllChildren( wand );
            for _,child in ipairs( children ) do
                local item = FindFirstComponentByType( child, "ItemComponent" );
                local permanent_action = false;
                if item ~= nil then
                    if ComponentGetValue( item, "permanently_attached" ) == "1" then
                        permanent_action = true;
                    end
                end
                EntityRemoveFromParent( child );
                local child_to_return = child;
                local components = EntityGetAllComponents( child );
                for _, component in ipairs( components ) do
                    local action_id = ComponentGetValue( component, "action_id" );
                    if action_id ~= nil and action_id ~= "" and Random() <= chance_to_replace then
                        -- TODO an assert will fail if the action type pool is empty
                        -- not too much that can be done about this right now, doesn't show up outside of dev
                        local action = GetRandomActionWithType( x, y, level or 6, extended_types[Random(1,#extended_types)], Random(0,1000)+_+x+y );
                        if action ~= nil and action ~= "" then
                            child_to_return = CreateItemActionEntity( action, x, y );
                            local item = EntityGetFirstComponent( child_to_return, "ItemComponent" );
                            if item ~= nil then
                                if permanent_action == true  then
                                    ComponentSetValue( item, "permanently_attached", "1" );
                                end
                            end
                            EntitySetComponentsWithTagEnabled( child_to_return, "enabled_in_world", false );
                        end
                    end
                end
                EntityAddChild( wand, child_to_return );
            end
        end
        if GameHasFlagRun( FLAGS.GuaranteedAlwaysCast ) then
            force_always_cast( wand, 1 )
        end

        if ability ~= nil then
            if GameHasFlagRun( FLAGS.OrderWandsOnly ) then
                ability_component_set_stat( ability, "shuffle_deck_when_empty", "0" );
            elseif GameHasFlagRun( FLAGS.ShuffleWandsOnly ) then
                ability_component_set_stat( ability, "shuffle_deck_when_empty", "1" );
            end

            if wandsmith_stacks > 0 then
                ability_component_adjust_stats( ability, {
                    mana_max=function(value) return tonumber( value ) * ( 1.1 ^ wandsmith_stacks ); end,
                    mana_charge_speed=function(value) return ( tonumber( value ) + Random( 10, 20 ) ) * ( 1.1 ^ wandsmith_stacks ); end,
                    deck_capacity=function(value) return math.min( 26, math.floor( tonumber( value ) + wandsmith_stacks * 2 ) ); end,
                    reload_time=function(value) return tonumber( value ) - Random( 8, 20 ) * wandsmith_stacks; end,
                    fire_rate_wait=function(value) return tonumber( value ) - Random( 4, 8 ) * wandsmith_stacks; end,
                    spread_degrees=function(value) return tonumber( value ) - 2 * wandsmith_stacks; end,
                } );
            end

            if mana_mastery_stacks > 0 then
                local mana_max = ability_component_get_stat( ability, "mana_max" );
                local mana_charge_speed = ability_component_get_stat( ability, "mana_charge_speed" );
                ability_component_set_stat( ability, "mana_max", (mana_charge_speed + mana_max) / 2 * 1.0 + mana_mastery_stacks * 0.1 );
                ability_component_set_stat( ability, "mana_charge_speed", (mana_charge_speed + mana_max) / 2 * 1.0 + mana_mastery_stacks * 0.1 );
            end
        end
    end
end