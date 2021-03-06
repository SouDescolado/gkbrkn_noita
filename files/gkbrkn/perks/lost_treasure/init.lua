dofile_once( "data/scripts/lib/utilities.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua" );

local tracker_variable = "gkbrkn_lost_treasure_tracker";
table.insert( perk_list,
    generate_perk_entry( "GKBRKN_LOST_TREASURE", "lost_treasure", false, function( entity_perk_item, entity_who_picked, item_name )
        local x, y = EntityGetTransform( entity_who_picked );
        local tracker = EntityGetFirstComponent( entity_who_picked, "VariableStorageComponent", tracker_variable );
        if tracker ~= nil then
            local spawner = EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/perks/lost_treasure/spawner.xml", 0, 0 );
            local current_lost_treasure_count = tonumber(ComponentGetValue( tracker, "value_string" ));
            EntityAddComponent( spawner, "VariableStorageComponent", {
                _tags=tracker_variable,
                name=tracker_variable,
                value_string=tostring(current_lost_treasure_count)
            });
            ComponentSetValue( tracker, "value_string", "0" )
            EntityAddChild( entity_who_picked, spawner );
        end
	end
) );