function shot( entity )
    local velocity = EntityGetFirstComponent( entity, "VelocityComponent" );
    if velocity ~= nil then
        local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
        local magnitude = math.sqrt( vx * vx + vy * vy );
        local angle = math.atan2( vy, vx );
        ComponentSetValue2( velocity, "mVelocity", math.cos( angle ) * magnitude * 1.33, math.sin( angle ) * magnitude * 1.33 );
    end
end