dofile_once("data/scripts/lib/utilities.lua");

local entity_id = GetUpdatedEntityID();
local distance_full = 50;
local distance_full_squared = distance_full ^ 2;
local x, y = EntityGetTransform( entity_id );

local projectiles = EntityGetInRadiusWithTag( x, y, distance_full, "projectile" ) or {};
if #projectiles > 0 then
    SetRandomSeed( GameGetFrameNum(), x + y + entity_id );
    local direction_random = math.rad( Random( -30, 30 ) );
	for _,projectile_entity in pairs( projectiles ) do
        local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
        if ComponentGetValue2( projectile, "mWhoShot" ) ~= entity_id then
            local px, py = EntityGetTransform( projectile_entity );
            local distance_squared = ( x - px ) ^ 2 + ( y - py ) ^ 2;
            
            if distance_squared < distance_full_squared then
                direction = get_direction( px, py, x, y );
        
                local velocity_components = EntityGetComponent( projectile_entity, "VelocityComponent" ) or {};
                
                local gravity_coeff = 96;
                local gravity_percent = math.max( ( distance_full_squared - distance_squared ) / distance_full_squared, 0.01 );
                
                for _,velocity in pairs( velocity_components ) do
                    local vx,vy = ComponentGetValue2( velocity, "mVelocity", vx, vy );
                    
                    local offset_x = math.cos( direction + direction_random ) * ( gravity_coeff * gravity_percent );
                    local offset_y = 0 - math.sin( direction + direction_random ) * ( gravity_coeff * gravity_percent );

                    vx = vx + offset_x;
                    vy = vy + offset_y;

                    ComponentSetValue2( velocity, "mVelocity", vx, vy );
                end
            end
        end
	end
end