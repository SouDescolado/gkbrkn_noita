--[[
UTILITY
    TODO
        Spell Power (utility stat on wand stat windows) (not yet possible?)

ACTIONS
    TODO
        Swarm Projectile Modifier (like Spellbundle, but a proper modifier and on enemies)
        Sticky Projectile Modifier (stick to surfaces / enemies) (useful for what kinds of projectiles?)

PERKS
    TODO
        Life Steal (1% of damage dealt is returned as life)
        Spell Steal ( n% gain an additional spell charge for a random (weighted by max use) spell in a random wand )
        Chaos (randomize projectile stuff)
        Stunlock Immunity (might be possible with small levels of knockback protection?)
        A permanent +2 to Wand Capacity
        Projectile Repulsion Field (projectiles within range are subtly repelled)
        The ability to swallow an item (wand, spell, flask?) and spit it back up upon taking damage? Kind of weird, but has interesting utility. Basically a janky additional inventory slot.
        Living Wand, basically create an either very healthy or immune Taikasauva of the wand you're currently holding (will be consumed to create the familiar.)
    NYI
        Dual Wield would probably be an excessively difficulty task to implement, but it would be cool if you could designate a Wand to dual wield.
        Lava, Acid, Poison (Material) Immunities (impossible for now? can ignore _all_ materials, but not individual materials)

ABANDONED
    Duplicate Projectile Modifier (dupe->quadshot->spark bolt = 4 spark bolts) (will be difficult) [someone already made this]
    Slot Machine (official mechanic)

]]

dofile( "files/gkbrkn/helper.lua");
dofile( "files/gkbrkn/config.lua");
ModLuaFileAppend( "data/scripts/gun/gun_extra_modifiers.lua", "files/gkbrkn/gun_extra_modifiers.lua" );
if PERKS.Enraged.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_enraged.lua" ); end
if PERKS.LivingWand.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_living_wand.lua" ); end
if PERKS.Duplicate.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_duplicate.lua" ); end
if PERKS.SpellEfficiency.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_spell_efficiency.lua" ); end
if PERKS.ManaEfficiency.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_mana_efficiency.lua" ); end
if PERKS.RapidFire.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_rapid_fire.lua" ); end
if PERKS.BleedGold.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_bleed_gold.lua" ); end
if PERKS.Sturdy.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_sturdy.lua" ); end
if PERKS.Resilience.Enabled then ModLuaFileAppend( "data/scripts/perks/perk_list.lua", "files/gkbrkn/perk_resilience.lua" ); end
if ACTIONS.ManaEfficiency.Enabled then ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "files/gkbrkn/action_mana_efficiency.lua" ); end
if ACTIONS.Curse.Enabled then ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "files/gkbrkn/action_curse.lua" ); end
if ACTIONS.MagicLight.Enabled then ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "files/gkbrkn/action_magic_light.lua" ); end
if ACTIONS.MicroShield.Enabled then ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "files/gkbrkn/action_micro_shield.lua" ); end
if ACTIONS.Spectral.Enabled then ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "files/gkbrkn/action_spectral.lua" ); end
if MISC.GoldPickupTracker.Enabled then dofile( "files/gkbrkn/gold_tracking.lua"); end

local test_gui = GuiCreate();
function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
    if SETTINGS.Debug then 
        dofile( "data/scripts/perks/perk.lua");
        dofile("data/scripts/gun/procedural/gun_action_utils.lua");
        local x, y = EntityGetTransform( player_entity );
        local effect = GetGameEffectLoadTo( player_entity, "EDIT_WANDS_EVERYWHERE", true );
        if effect ~= nil then
			ComponentSetValue( effect, "frames", "-1" );
		end
        --TryGivePerk( player_entity, "GKBRKN_RESILIENCE" );
        local debug_wand = EntityLoad("files/gkbrkn/placeholder_wand.xml", x, y);
        AddGunAction( debug_wand, "GKBRKN_MICRO_SHIELD" );
        AddGunAction( debug_wand, "GKBRKN_SPECTRAL" );
        AddGunAction( debug_wand, "LIGHT_BULLET" );
        local inventory = EntityGetNamedChild( player_entity, "inventory_quick" );
        if inventory ~= nil then
            EntityAddChild( inventory, debug_wand );
        end
        EntityLoad( "data/entities/animals/deer.xml", x - 80, y );
        EntityLoad( "data/entities/items/pickup/goldnugget.xml", x + 20, y - 20 );
        EntityLoad( "data/entities/projectiles/deck/touch_gold.xml", x +30, y + 20 );
    end
    if MISC.GoldPickupTracker.Enabled and MISC.GoldPickupTracker.ShowTracker and EntityGetFirstComponent( player_entity, "SpriteComponent", "gkbrkn_gold_tracker" ) == nil then
        EntityAddComponent( player_entity, "SpriteComponent", { 
            _tags="gkbrkn_gold_tracker,enabled_in_world",
            image_file="files/gkbrkn/font_pixel_white.xml", 
            emissive="1",
            is_text_sprite="1",
            offset_x="8", 
            offset_y="-4", 
            update_transform="1" ,
            update_transform_rotation="0",
            text="",
            has_special_scale="1",
            special_scale_x="0.6667",
            special_scale_y="0.6667",
            z_index="1.6",
        } );
    end
end

function OnWorldPostUpdate()
    if GoldTrackerUpdate ~= nil then GoldTrackerUpdate(); end
    if RenderLog ~= nil then
        GuiStartFrame( test_gui );
        GuiLayoutBeginVertical( test_gui, 1, 12 );
        RenderLog( test_gui );
        GuiLayoutEnd( test_gui );
    end
end
