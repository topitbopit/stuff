--- Labyrinth Item Esp
-- Made by topit

shared.labyrinthEsp = {
    settings = {
        -- Render settings 
        max_draw_distance = 1000; -- Disables drawing of ESPs that are further away than this setting 
        text_size = 18; -- Size of the ESP text
        distance_scale = false; -- Changes scaling of ESP based off of distance 
        optimized_updating = false; -- Updates only one ESP manager per frame - boosts your fps, but some ESP looks even more delayed
        culled_refresh_rate = 0.3; -- How long to wait inbetween off-screen ESP updates. In other words, higher number = less lag, but more delay 
        
        -- Script settings 
        destroy_bind = 'End'; -- Keybind for destroying the script - refer to https://create.roblox.com/docs/reference/engine/enums/KeyCode
        rarity_level = 4; -- Rarity required to ESP an item. 1 is common, 2 is uncommon, 3 is rare, etc.
        rarity_specific = false; -- If true, only items with the rarity equal to rarity_level get ESP'd. If false, items equal to and above rarity_level get ESP'd.
        item_types = { 'Fish', 'Ores', 'Trees', 'Ingredients' }; -- What types of item to ESP. Options are 'Fish', 'Ores', 'Trees', and 'Ingredients'
        
        -- Display settings 
        background_box = true; -- Shows a background box behind each ESP, making it easier to read 
        distance_label = true; -- Shows a label displaying how far away you are from the item
        rarity_label = true; -- Shows a label displaying the item's rarity
        item_label = true; -- Shows a label displaying the item's name 
    };
}

loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/stuff/main/TheLabyrinth/ItemEsp/source.lua'))()
