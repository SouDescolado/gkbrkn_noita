dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
table.insert( actions, generate_action_entry(
    "GKBRKN_REVELATION", "revelation", ACTION_TYPE_MODIFIER, 
    "0,1,2,3,4,5,6", "1,1,1,1,1,1,1", 100, 3, -1,
    nil,
    function()
        c.extra_entities = c.extra_entities .. "mods/gkbrkn_noita/files/gkbrkn/actions/revelation/projectile_extra_entity.xml,";
        draw_actions( 1, true );
    end
) );