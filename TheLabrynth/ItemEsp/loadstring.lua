--- Labrynth Item Esp
-- Made by topit

shared.labrynthEsp = {
    settings = {
        -- Render settings 
        max_draw_distance = 6000; -- Disables drawing of ESPs that are further away than this setting 
        text_size = 18; -- Size of the esp text
        distance_scale = true; -- Changes scaling of esp based off of distance 
        optimized_updating = true; -- Updates only one ESP manager per frame - boosts your fps, but some esp looks even more delayed
        
        -- Script settings 
        destroy_bind = 'End'; -- Keybind for destroying the script - refer to https://create.roblox.com/docs/reference/engine/enums/KeyCode
        rarity_level = 3; -- Rarity required to esp an item. 1 is common, 2 is uncommon, 3 is rare, etc.
        item_types = { 'Fish', 'Ores', 'Trees', 'Ingredients' }; -- What types of item to esp, options are 'Fish', 'Ores', 'Trees', and 'Ingredients'
        
        -- Display settings 
        background_box = true; -- Shows a background box behind each ESP, making it easier to read 
        distance_label = true; -- Shows a label displaying how far away you are from the item
        rarity_label = true; -- Shows a label displaying the item's rarity
        item_label = true; -- Shows a label displaying the item's name 
    };
}

loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/stuff/main/TheLabrynth/ItemEsp/source.lua'))()
