function shot( entity )
    local x, y = EntityGetTransform( entity );
    local projectile = EntityGetFirstComponent( entity, "ProjectileComponent" );
    if projectile ~= nil then
        local effect_entities = ComponentGetValue2( projectile, "damage_game_effect_entities" );
        ComponentSetValue2( projectile, "blood_count_multiplier", 0 );
        ComponentSetValue2( projectile, "damage_game_effect_entities", effect_entities.."mods/gkbrkn_noita/files/gkbrkn/champion_types/burning/effect_burn.xml," );
        EntityAddChild( entity, EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/champion_types/burning/burn_shot.xml", x, y ) );
        ComponentSetValue2( projectile, "on_collision_spawn_entity", true );
        ComponentSetValue2( projectile, "spawn_entity", "" );
    end
end