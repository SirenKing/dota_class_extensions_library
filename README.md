# dota_class_extensions_library
Encapsulates common/useful tasks as methods for general use. Requires some tools/methods from the basic Butt Template here: https://github.com/Snoresville/dota2buttemplate_fixed.

If you are new to modding, be sure to follow the instructions in the template's README. They are well-written and easy to follow.

# GETTING STARTED:
To use this code, simply copy the following files from this repository into your 'vscripts/` folder:
- "extend_abilities.lua"
- "extend_npc.lua
  
Next, put this code at the top of your 'addon_game_mode.lua' file, but under any other lines starting with 'require':

```lua
require("extend_abilities")
require("extend_npc")
```

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

Finally, add the `npc_units_extension.txt` file in this repo to the `scripts/npc` folder in your mod folder. Then add this line to the very top of your project's `npc_units_custom.txt` file, above the line that says "DOTAUnits":
```#base npc_units_extension.txt```

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
