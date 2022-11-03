--- Drawing Player Radar
--- Made by topit

_G.RadarSettings = {
    -- Radar settings
    RADAR_LINES = true; -- Displays distance rings
    RADAR_SCALE = 1; -- Controls how "zoomed in" the radar display is 
    RADAR_RADIUS = 125; -- The size of the radar itself
    RADAR_LINE_DISTANCE = 50; -- The distance between each line
    RADAR_ROTATION = true; -- Toggles radar rotation. Looks kinda trippy when disabled
    SMOOTH_ROT = true; -- Rotates the radar smoothly
    SMOOTH_ROT_AMNT = 20; -- Lower number is smoother, higher number is snappier 
    CARDINAL_DISPLAY = true; -- Displays each cardinal direction (NSWE) around the radar 

    -- Marker settings
    USE_QUADS = true; -- Displays radar markers as arrows instead of dots 
    OFFSCREEN_TRANSPARENCY = 0.3; -- Transparency of offscreen markers
    DISPLAY_TEAM_COLORS = true; -- Sets the radar markers' color to their player's team color
    DISPLAY_OFFSCREEN = true; -- Leaves offscreen markers visible
    DISPLAY_TEAMMATES = true; -- Shows your teammates' markers
    MARKER_SCALEMIN = 0.75; -- Minimium scale radar markers can be. Marker falloff bypasses this limit!
    MARKER_SCALEMAX = 1.75; -- Maximum scale radar markers can be. Marker falloff bypasses this limit!
    MARKER_FALLOFF = false; -- Affects the markers' scale depending on how far away the player is
    MARKER_FALLOFF_AMNT = 500; -- How close someone has to be for falloff to start affecting them 

    -- Theme
    RADAR_THEME = {
        Outline = Color3.fromRGB(35, 35, 45); -- Radar outline
        Background = Color3.fromRGB(25, 25, 35); -- Radar background
        DragHandle = Color3.fromRGB(50, 50, 255); -- Drag handle 
        
        Cardinal_Lines = Color3.fromRGB(110, 110, 120); -- Color of the horizontal and vertical lines
        Distance_Lines = Color3.fromRGB(65, 65, 75); -- Color of the distance rings
        
        Generic_Marker = Color3.fromRGB(255, 25, 115); -- Color of a player marker without a team
        Local_Marker = Color3.fromRGB(115, 25, 255); -- Color of your marker, regardless of team
    };
}

loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/stuff/main/PlayerRadar/source.lua'))()
