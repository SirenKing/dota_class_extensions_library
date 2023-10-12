# dota_class_extensions_library
Encapsulates common/useful tasks as methods for general use. Requires some tools/methods from the basic Butt Template here: https://github.com/Snoresville/dota2buttemplate_fixed.

If you are new to modding, be sure to follow the instructions in the template's README. They are well-written and easy to follow.

# GETTING STARTED:
To use this code, simply copy the following files from this repository into your 'vscripts` folder:
- extend_abilities.lua
- extend_npc.lua
  
Next, put this code at the top of your 'addon_game_mode.lua' file, but under any other lines starting with 'require':

```lua
require("extend_abilities")
require("extend_npc")
```

Put 'weak_creature.lua' in your vscripts/abilities folder.

Inside the filters.lua file, search for the function called ```Filters:DamageFilter(event)``` and add the following code after the local variables:

```lua
    if attackerUnit and attackerUnit.hero_parent~=nil and attackerUnit.hero_parent:IsRealHero() then
        local damage_table = {
            victim = victimUnit,
            attacker = attackerUnit.hero_parent,
            damage = event.damage,
            damage_type = event.damagetype_const,
            ability = ability
        }
        ApplyDamage(damage_table)
		return false
    end
```
This code is specifically included so that heroes are credited with the damage dealt -and any kills- by any 'subcasters' they summon. Normally, it is good practice to instead set the unit's 'owner' with the built-in method ```unit:SetOwner( hero )``` and then use ```unit:GetOwner( hero )``` to retrieve this information. In this case, however, bots will try to control any units they 'own' and this causes severe lag, so these units should not be 'owned.'

Add the `npc_abilities_extension.txt` file to the `scripts/npc` folder in your mod folder. Then add this line to the very top of your project's `npc_abilities_custom.txt` file, above the line that says "DOTAAbilities":
```#base npc_abilities_extension.txt```

Finally, add the `npc_units_extension.txt` file to the `scripts/npc` folder in your mod folder. Then add this line to the very top of your project's `npc_units_custom.txt` file, above the line that says "DOTAUnits":
```#base npc_units_extension.txt```

After following these steps, you should be ready to use the extended npc and ability classes

# API: Ability Class:

`ParentOverrideCurrentGesture( GameActivity_t )` Stop this unit's current gesture and replace it with the one you define. Takes a [GameActivity_t](https://moddota.com/api/#!/vscripts/GameActivity_t) enum.

`ApplyDamageToEnemiesWithin( v_location, int_radius, int_damage, enum_dmgType )` At [v_location](https://moddota.com/api/#!/vscripts?search=vector) on the map, deal int_damage to basic enemies within int_radius, the damage type being [enum_dmgType](https://moddota.com/api/#!/vscripts/DAMAGE_TYPES). Bear in mind that the damage type is an enum, not a string (it will not work if you put quotes around the enum).

`FindClosestBasicEnemyWithin( int_radius )` Find and return the closest general enemy within int_radius.

`FindBasicEnemiesWithin( v_targetPos, int_radius )` Return an array of all general enemies within int_radius.

`CreateIndicator( v_location, fl_duration, int_radius )` At a [v_location](https://moddota.com/api/#!/vscripts?search=vector) on the map, create a red warning indicator (particle) of int_radius.

`GetRandomPointInRadius( v_location, int_minDist, int_maxDist )` Return a random [v_location](https://moddota.com/api/#!/vscripts?search=vector) that is at least int_minDist from the inputted [v_location](https://moddota.com/api/#!/vscripts?search=vector) and less than or equal to int_maxDist from the same location.

`GetRandomPointInSquare( v_location, int_minXY, int_maxXY )` Return a random [v_location](https://moddota.com/api/#!/vscripts?search=vector) that is at least int_minDist distance horizontally and vertically from the input [v_location](https://moddota.com/api/#!/vscripts?search=vector) and less than or equal to distance horizontally and vertically from the same location.

`IsAMapAbility()` Return a bool stating whether this ability is a 'map' ability ('map' abilities are the hidden passives that every hero has that allows them to interact with Outposts, Lotus Pools, Gates, etc.

`IsAMainAbility()` Return whether this bool stating whether this ability is a 'map' ability for the hero. This includes hidden/secondary abilities that are unique to this hero. This EXCLUDES talents, "generic_hidden' and map abilities.

`GetAllAbilitySpecials()` Return a kv array where'k' = the name of the ability value and 'v' = the value. Usually, you would use `for k,v in pairs(table) do' loop to access the k and the v as seperate variables.

`GetHasAbilitySpecialWith( name_str )` Return whether this bool stating whether this ability has an AbilitySpecial name/key that contains the input string.

`GetFirstAbilitySpecialNameContaining( name_str )` Return the value of FIRST AbilitySpecial name/key that contains the input string.

`GetCastTypeString()` Return the string form of the ability's 'AbilityBehavior' (The 'AbilityBehavior' value can also be found by looking at your kv files and looking at the 'AbilityBehavior' value). The returned value will usually look something like this "DOTA_ABILITY_BEHAVIOR_PASSIVE | DOTA_ABILITY_BEHAVIOR_HIDDEN" and you will need to parse or string.match to get what you are looking for.

`GetReturnReleaseOrEndAbilityName()` Return this ability's secondary ability (if there is one) listed in 'ability_exceptions.txt.' This function does NOT rely on `GetAssociatedSecondaryAbilities()` or similar methods because they are not reliable.

`IsReturnReleaseOrEndAbilityName()` Return whether this ability is listed as a 'secondary' ability in 'ability_exceptions.txt. This function does NOT rely on `GetAssociatedSecondaryAbilities()` or similar methods because those are not reliable.

`BeginCastStormRadial( ability_name, origin, cast_qty, delay, min_dist, max_dist, min_radius, max_radius, b_randomize_origin )` This ability will use it's caster, subcasters, and location to repeatedly cast the named ability in random locations around the origin, using the rest of the variables as extra data.

`SplitSubcast( ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, length_int, vector_cast_rotation )` This ability will use it's caster, subcasters, and location to repeatedly cast the named ability in a specified patter around the origin, using the rest of the variables as extra data.

# API: NPC Class:

`PlaySequenceWithRateModifier( act_enum, seq_str, rate, dur )` Force this npc to play a specific animation sequence for it's current model. This method is not like `ForcePlayActivityOnce()` or 'StartGesture()' which play a random animation related to the enum you provide, such as a random `ACT_IDLE` animation or a random 'ACT_WALK' animation. Instead, this method plays the specific animation you listed that is related to the ACT enum you provide, also allowing you to specify a playback rate and duration. If the duration is nil then the animation will play once and then stop.

`CreateSubcasters( num )` Create `num` amount of subcasters for this unit to use. These 'subcasters' are the 'npc_dota_subcaster' unit defined in the npc_units_extension.txt provided in this repo.

`GetSubcasters()` Get an array of all the subcaster units associated with this unit. Bear in mind; these subcasters are not 'owned' by this unit (because bot try to control the units they own, cause lag in this case).

`GetIdleSubcasters()` Get an array of all the subcaster units associated with this unit, but for which '.busy' == false. When a subcaster casts an ability, they are considered 'busy' for the next 8 seconds, or while they are still channeling.

`GetDistToPos( pos )` Get the literal distance between this unit's [v_location](https://moddota.com/api/#!/vscripts?search=vector) and the given [v_location](https://moddota.com/api/#!/vscripts?search=vector). Unlike `FindPathLength()`, this method returns the distance without regard for terrain or movement capabilities. This method also disregards world height, returning only the distance for xy and xy.

`GetHerosMainAbilities()` Get an array of all this heroes 'main' abilities' names, excluding 'map' abilities and talents and 'generic_hidden.'

`DelayCastWithOrders( order_params, delay )` Currently, this is just `ExecuteOrderFromTable()` wrapped in a table. In the future, this method will reconcile issues with any `ExecuteOrderFromTable()` you call and let you know in the console.

# IMPORTANT AND USEFUL STUFF:
[Moddota's API tools and Tutorials](https://moddota.com/api/#!/vscripts)

[DotA Butt Tutorial Video (from Baumi)](https://www.youtube.com/watch?v=SuGO-Fljpqs)

[PANORAMA API](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Panorama/Javascript/API)

[Valve's API and Tutorials Wiki](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools): Includes lists of built-in ability names, event names, item names, etc.

[Sample LUA Abilities](https://github.com/Elfansoer/dota-2-lua-abilities): Elfonsoer's code, which closely mimics the abilities in native DotA. This is NOT the same code that DotA actually uses (DotA's original abilities are written in C and C++, whereas Elfansoer's abilities are written in LUA and only mimics the general behavior of the ability at the time the LUA was written). This code is extremely useful for creating your own abilities and/or understanding ways to code certain behaviors. When using someone else's code, it is important to credit them at the top of the file and -ideally- in the description of the mod when you publish the mod. Usually, if the code is publicly-exposed on GitHub then it is okay to use it so long as your credit the coder.

[Game-Tracking for Up-To-Date DotA](https://github.com/SteamDatabase/GameTracking-Dota2/tree/master/game)

[Cosmetic Item Names/IDs](https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/scripts/items/items_game.txt)
- Find cosmtic items/names by hero: https://dota2.fandom.com/wiki/Equipment
- Add these cosmetics to a unit in a mod: https://moddota.com/units/create-creature-attachwearable-blocks-directly-from-the-keyvalues/

[DotA's addon_english.txt](https://github.com/SteamDatabase/GameTracking-Dota2/blob/master/game/dota_addons/dungeon/resource/addon_english.txt): Great for identifying how DotA creates/styles tooltips for use in-game. Use this as a reference for creating your own item/ability tooltips.

Images/Icons:
- [Icon Creation Tutorial](https://steamcommunity.com/sharedfiles/filedetails/?id=221135424)
- [Ability Icons](https://dota2.fandom.com/wiki/Category:Ability_icons)
- [Item Icons](https://dota2.fandom.com/wiki/Category:Item_icons)
- [Custom Item Icons 1 (Fandom Wiki Items)](https://dota2.fandom.com/wiki/Category:Custom_item_icons)
- [Custom Item Icons 2 (DeviantArt Consumeables)](https://www.deviantart.com/majan22/art/Consumable-Items-icons-for-Dota-2-mods-540681314)
- [Custom Item Icons 3 (DeviantArt Other)](https://www.artstation.com/artwork/WdmOD)https://www.artstation.com/artwork/WdmOD)
- [Custom Item Icons 4 (Reddit)](https://www.reddit.com/r/DotA2/comments/3ajoqo/free_custom_item_icons_for_modders/)
- [Custom Item Icons 5 (HiveWorkshop Forum)](https://www.hiveworkshop.com/threads/item-icons-for-mods.266901/)
- [Custom Item/Ability Icons 6 (This Repo)](https://github.com/SirenKing/dota_class_extensions_library/tree/main/custom_icons)
- Easily Create Your Own Icons: search for a 3D model using DotA's tools, set the preview background to whatever color you prefer, then screenshot the model and use Photoshop's Anistropic filter a couple of times to cause the items to appear 'digitally painted' like DotA's native item icons. If you don't have Photoshop, other programs such as GIMP and ProCreate also have filters you can use.
