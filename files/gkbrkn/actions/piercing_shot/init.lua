dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
table.insert( actions, generate_action_entry(
    "GKBRKN_PIERCING_SHOT", "piercing_shot", ACTION_TYPE_MODIFIER,
    "0,1,2,3,4,5,6", "1,1,1,1,1,1,1", 250, 9, -1,
    nil,
    function()
        c.damage_projectile_add = c.damage_projectile_add + 0.24;
        c.extra_entities = c.extra_entities .. "mods/gkbrkn_noita/files/gkbrkn/actions/piercing_shot/projectile_extra_entity.xml,";
        draw_actions( 1, true );
    end
) );
