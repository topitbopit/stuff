-- BMP Parser, version 0.1.0
-- Written by topit
-- Only supports decoding rn

--[[
Example: 

local bitmap = Bitmap.decode(image data)
bitmap:Parse()
local pixels = bitmap:GetPixels()
local resolution = bitmap:GetResolution()

bitmap:Destroy()
]]

--------------------------------


--- Integer math
-- Precomputed array of values used to
-- speed up integer casting
local CastLookup = {
    256 ^ 0;
    256 ^ 1;
    256 ^ 2;
    256 ^ 3;
}

-- Takes an array of bytes and converts
-- them to a single integer.
-- Ex: 0x20, 0x21 -> 8480
local function CastFromBytes(bytes) 
    local int = 0
    for idx = 1, #bytes do 
        local d = CastLookup[idx]
        int = int + ( d * bytes[idx] )
    end
    return int
end

-- Takes an integer and converts it
-- to an array of bytes. Limited to int32s, for an output
-- of up to 4 bytes.
-- Ex: 8480 -> 32, 33 (hex 0x20, 0x21 converted to decimal)
local function CastToBytes(int)
    local bytes = {}
    
    local o = int
    for idx = 4, 1, -1 do 
        local d = CastLookup[idx]
        
        if ( d < int ) then -- Safety check just to make sure extra empty bytes arent added
            local byte = math.floor(o / d) -- Could use bit shifting instead but this works
            bytes[idx] = byte
            o = o % d
        end
    end
    
    return bytes
end

-- Returns the maximum value
-- for the type of int that `int` is - 
-- ex: 63 -> 64, 100 -> 128, 172 -> 256
local function GetMaxInt(int) 
    for i = 1, 64 do 
        local d = 2 ^ i
        if ( int < d ) then
            return d
        end
    end
end

-- Takes a byte and splits it into 2 4 bit values,
-- returning the upper 4 bits first
local function SplitByte(byte) 
    local lower = byte % 16
    local upper = math.floor(byte / 16)
    return upper, lower 
end

-- Takes bytes and converts them to a string 
local function BytesToStr(bytes) 
    local str = ''
    for i = 1, #bytes do 
        str ..= string.char(bytes[i])
    end
    return str
end

--- FileStream class
-- Essentially a bloated wrapper for string.sub,
-- used to easily read file data in the most retarded way possible.
local FileStream = {} do 
    FileStream.__index = FileStream
    
    FileStream.Head = nil -- Character index that the head is at
    FileStream.Stream = nil -- Stream to read from 
    
    
    -- Reads x amount of bytes and returns what was read, without
    -- seeking the head forwards or backwards.
    function FileStream:Peek(size: number) 
        local headPosition = self.Head
        local data = self.Stream:sub(headPosition, headPosition + size - 1)
        
        return data 
    end
    
    -- Advances the head `offset` bytes, without
    -- returning anything.
    function FileStream:Advance(offset: number) 
        self.Head += offset
    end
    
    -- Seeks the head to a specified location.
    function FileStream:SeekTo(location: number)
        self.Head = location
    end
    
    -- Reads and stores `size` amount of bytes from the stream, 
    -- seeks the head forward `size` bytes, and returns the 
    -- data that was stored.
    function FileStream:Read(size: number) 
        local headPosition = self.Head
        local newPos = headPosition + size
        
        local data = self.Stream:sub(headPosition, newPos - 1)
        
        self.Head = newPos
        
        return data
    end
    
    -- Reads `size` bytes and returns the data parsed
    -- as an unsigned integer.

    -- *Note: To increase speed, several functions used by ReadInt
    -- were inlined. This is why the code looks pretty garbage*
    function FileStream:ReadInt(size: number) 
        
        -- FileStream:Read
        local HeadPosition = self.Head
        local NewPos = HeadPosition + size 
        
        local data = self.Stream:sub(HeadPosition, NewPos - 1)
        
        self.Head = NewPos
        
        -- CastFromBytes
        local int = 0
        for idx = 1, #data do 
            local byte = string.byte(data:sub(idx, idx))
            local d = CastLookup[idx]
            int += (d * byte)
        end
        return int 
    end
    
    
    -- Reads a single byte, and returns it as an integer
    function FileStream:ReadByte() 
        local HeadPosition = self.Head
        
        local data = self.Stream:sub(HeadPosition, HeadPosition)
        
        self.Head += 1 
        
        return string.byte(data) 
    end
    
    -- Returns true if this Stream has finished reading
    -- all of it's data, false if it has not.
    function FileStream:ReachedEnd() 
        return self.Head >= #self.Stream
    end
    
    -- Destroys this FileStream instance.
    function FileStream:Destroy() 
        self.Head, self.Stream = nil, nil
        setmetatable(self, nil)
    end
    
    -- Creates and returns a new FileStream instance,
    -- with the Stream set to `stream`.
    function FileStream.new(stream: string) 
        local newStream = setmetatable({}, FileStream)
        newStream.Stream = stream 
        newStream.Head = 1
        
        return newStream
    end
end

-- Color4 class
local Color4 = {} do 
    Color4.__index = Color4
    Color4.__tostring = function(obj) 
        return ('(%s, %s, %s, %s)'):format(obj.R, obj.G, obj.B, obj.A)
    end
    Color4.__eq = function(obj1, obj2) 
        return ( obj1.R == obj2.R ) and ( obj1.G == obj2.G ) and ( obj1.B == obj2.B ) and ( obj1.A == obj2.A )
    end
    
    -- Creates a new Color4 instance, with the given red, green, blue,
    -- and alpha channels. All inputs will be clamped to a range of [0 - 255]
    function Color4.fromRGBA(R: number, G: number, B: number, A: number) 
        local ColorObject = setmetatable({}, Color4)
        ColorObject.R = math.clamp(R, 0, 255)
        ColorObject.G = math.clamp(G, 0, 255)
        ColorObject.B = math.clamp(B, 0, 255)
        ColorObject.A = math.clamp(A, 0, 255)
        
        return ColorObject
    end 
    
    -- Creates a new Color4 instance, with the given blue, green, red,
    -- and alpha channels. All inputs will be clamped to a range of [0 - 255]
    function Color4.fromBGRA(B: number, G: number, R: number, A: number) 
        local ColorObject = setmetatable({}, Color4)
        ColorObject.B = math.clamp(B, 0, 255)
        ColorObject.G = math.clamp(G, 0, 255)
        ColorObject.R = math.clamp(R, 0, 255)
        ColorObject.A = math.clamp(A, 0, 255)
        
        return ColorObject
    end 

    -- Creates a new Color4 instance, with the given blue, green, red,
    -- and alpha channels. **All inputs must be in the range of [0 - 255], as they won't be clamped**
    function Color4.fast(B: number, G: number, R: number, A: number) 
        local ColorObject = setmetatable({}, Color4)
        ColorObject.B = B
        ColorObject.G = G 
        ColorObject.R = R 
        ColorObject.A = A 


        return ColorObject 
    end
    
    -- Overwrites an already existing Color4 object's R, G, B, and A values
    -- to the inputs. All inputs will be clamped to a range of [0 - 255]
    function Color4:SetRGBA(R: number, G: number, B: number, A: number)
        self.R = math.clamp(R, 0, 255)
        self.G = math.clamp(G, 0, 255)
        self.B = math.clamp(B, 0, 255)
        self.A = math.clamp(A, 0, 255)
    end
    -- Returns a Color3 using the Color4's red, green, and blue components
    function Color4:ToColor3() 
        return Color3.fromRGB(self.R, self.G, self.B)
    end
    
    -- Converts a Color4's alpha channel to a roblox-compatible Transparency value,
    -- where an alpha of 255 (full visible) equals 0, and an alpha of 0 (invisible) equals 1.
    function Color4:ToTransparency() 
        return 1 - (self.A / 255)
    end
    
    -- Converts a Color4's alpha channel to an "opacity" value - 0 is invisible, 1 is visible
    -- Equal to Color4.A / 255
    function Color4:ToOpacity() 
        return (self.A / 255)
    end
end


local Bitmap = {} do 
    Bitmap.__index = Bitmap
    
    Bitmap.HeaderTypes = {
        [40] = 'BITMAPINFOHEADER';
        [124] = 'BITMAPV5HEADER';
    }
    
    local errorFormat = '%s failed; %s'
    
    -- Creates a new Bitmap object from `ABMPData`.
    -- Optionally lets you limit only bitmaps with 
    -- the reserve integer matching `reservedInt`.
    function Bitmap.decode(ABMPData: string, AReservedInt: number) -- BMP data string, optional reserved int to use
        -- Resources
        -- https://en.wikipedia.org/wiki/BMP_file_format
        -- https://gibberlings3.github.io/iesdp/file_formats/ie_formats/bmp.htm
        -- https://www.fileformat.info/format/bmp/egff.htm
        
        local ThisStream = FileStream.new(ABMPData) -- Create stream for bitmap 
        
        local HeaderInfo = {} -- Used to store information about the bitmap for later use
        
        --- BITMAP HEADER PROCESSING
        HeaderInfo.HeaderField = ThisStream:Read(2) -- Bitmap header field. Used to tell if the file is a proper BMP
        
        -- Check and error immediately if the file isnt valid, just so nothing goes wrong later
        if ( HeaderInfo.HeaderField ~= 'BM' ) then
            ThisStream:Destroy()
            HeaderInfo = nil
            return error(errorFormat:format('Bitmap.new', 'Not a valid bitmap; expected the Windows style BM format'), 2)
        end
        
        HeaderInfo.FileSize = ThisStream:ReadInt(4) -- The size of the entire file, read from the bitmap header
        
        -- Just as before, compare file sizes and error immediately if they don't match, just so nothing goes wrong
        if ( HeaderInfo.FileSize ~= #ABMPData ) then
            ThisStream:Destroy()
            HeaderInfo = nil
            return error(errorFormat:format('Bitmap.new', 'Bitmap filesize is mismatched'), 2)
        end
        
        HeaderInfo.ReservedInt = ThisStream:ReadInt(4)
        
        -- Check if reservedInt is being used
        if ( typeof(AReservedInt) == 'number' ) then 
            -- If so, compare the reserve bytes to the int and 
            -- exit if they don't match
            
            if ( HeaderInfo.ReservedInt ~= AReservedInt ) then
                ThisStream:Destroy()
                HeaderInfo = nil
                return false 
            end
        end
        
        HeaderInfo.ImageOffset = ThisStream:ReadInt(4) -- The offset the image data is at. For example, an offset of 50 (0x32 in hex) would place the image data at 51 (0x33)
        
        --- DIB HEADER PROCESSING
        -- This is based off of the BITMAPINFOHEADER header
        
        --local DIB_HPOS_BEFORE = ThisStream.Head -- The header position before reading the DIB header
        
        HeaderInfo.DibHeaderSize  = ThisStream:ReadInt(4) -- The size of the DIB header. If not 40 / 124, this will cause an error; any other size is an unsupported DIB header.
        HeaderInfo.BitmapWidth    = ThisStream:ReadInt(4) -- Bitmap image width. Different than the horizontal resolution found later in the file.
        HeaderInfo.BitmapHeight   = ThisStream:ReadInt(4) -- Bitmap image height. Different than the vertical resolution found later in the file.
        HeaderInfo.PlaneCount     = ThisStream:ReadInt(2) -- Amount of color planes in the bitmap. Most parsers require this value to be 1.
        
        HeaderInfo.BitDepth       = ThisStream:ReadInt(2) -- The bits per pixel / color depth. 4, 8, 24, and 32 are supported, as they are fairly common.
        HeaderInfo.CompressType   = ThisStream:ReadInt(4) -- Compression method. Must be 0 (no compression) or 3 (bitfield compression, but i have no clue what this does so i treat it as no compression).
        HeaderInfo.RawImageSize   = ThisStream:ReadInt(4) -- The raw, uncompressed image size. If no compression is used, this value can be (and most of the time is) 0.
        
        HeaderInfo.HorResolution  = ThisStream:ReadInt(4) -- Horizontal resolution, but in pixels per meter????? (idk)
        HeaderInfo.VerResolution  = ThisStream:ReadInt(4) -- Vertical resolution, but in pixels per meter????? (idk)
        
        HeaderInfo.PaletteEntries = ThisStream:ReadInt(4) -- The amount of colors within the palette.
        HeaderInfo.ImportantCols  = ThisStream:ReadInt(4) -- Important colors. Can be 0, making every color important.
        
        HeaderInfo.HeaderType = Bitmap.HeaderTypes[HeaderInfo.DibHeaderSize]
        
        --local DIB_HPOS_AFTER = ThisStream.Head -- The header position after reading the DIB header
        
        -- Safety checks are placed below for organization
        
        
        -- Color plane check - the amount of color planes must be 1 
        if ( HeaderInfo.PlaneCount ~= 1 ) then
            ThisStream:Destroy()
            HeaderInfo = nil 
            return error(errorFormat:format('Bitmap.new', 'Color plane count is incorrect; expected 1'), 2)
        end
        
        -- Header check - if the header used is unsupported, return an error
        if ( not HeaderInfo.HeaderType ) then
            ThisStream:Destroy()
            HeaderInfo = nil 
            return error(errorFormat:format('Bitmap.new', 'This bitmap uses an unsupported DIB header'), 2)
        end
        
        -- Automate palette entries
        if ( HeaderInfo.BitDepth <= 8 and HeaderInfo.PaletteEntries == 0 ) then
            HeaderInfo.PaletteEntries = 2 ^ HeaderInfo.BitDepth
        end
        
        local thisBitmap = setmetatable({}, Bitmap)
        thisBitmap.HeaderInfo = HeaderInfo
        thisBitmap.Stream = ThisStream
        
        return thisBitmap
    end

    function Bitmap:Parse()
        local HeaderInfo = self.HeaderInfo
        local ThisStream = self.Stream
        
        if ( HeaderInfo.BitDepth > 8 and HeaderInfo.PaletteEntries ~= 0 ) then
            warn('Expected 0 palette entries for a BMP with more than 8 bits per pixel. Parsing may be done incorrectly!')
        end
        
        --- DECODING
        if ( HeaderInfo.CompressType == 0 ) then
            
            if ( HeaderInfo.BitDepth == 4 ) then 
                -- 4 bits per pixel
                
                local palette = {} -- Anything lower than 8 bits per pixel uses a color palette
                
                for i = 1, HeaderInfo.PaletteEntries do 
                    -- BGRA format has to be used because little endian bullshit
                    
                    local B = ThisStream:ReadByte() -- Blue
                    local G = ThisStream:ReadByte() -- Green
                    local R = ThisStream:ReadByte() -- Red
                    ThisStream:Advance(1) -- Reserved byte, goes unused in this specific format
                    
                    palette[i - 1] = Color4.fromBGRA(B, G, R, 0xFF) -- 0xFF for the funnies
                end
                
                -- Setup 2d array of pixels
                local pixels = {}
                
                -- In bitmaps, the pixel data is bottom up, left to right (because fuck you)
                -- So the parser starts at the bottom and makes its way up
                
                -- Instead of skipping ahead and reading backwards, making the pixel data be read up to down like expected,
                -- the direction looped just goes in reverse since thats easier
                
                local BitmapWidth = HeaderInfo.BitmapWidth -- Localization just to save some speed
                
                local chunkWidth = GetMaxInt(BitmapWidth) -- Bitmap width + padded 0s
                local padAmount = BitmapWidth - chunkWidth
                
                for y = HeaderInfo.BitmapHeight, 1, -1 do 
                    local thisRow = {}
                                            
                    -- Loop over every single byte except for the final one
                    -- Check if the width is even, if so then loop normally
                    -- Otherwise leave off the final byte and handle it on its own 
                    -- (odd widths make one byte only have one pixel)
                    
                    if ( BitmapWidth % 2 == 0 ) then 
                        for x = 1, BitmapWidth, 2 do 
                            local Byte = ThisStream:ReadByte() -- The current byte, which contains two pixels
                            local Pixel1, Pixel2 = SplitByte(Byte) -- First pixel and second pixel
                            
                            thisRow[x] = palette[Pixel1]
                            thisRow[x + 1] = palette[Pixel2]
                        end
                    else
                        for x = 1, BitmapWidth - 2, 2 do 
                            local Byte = ThisStream:ReadByte()
                            local Pixel1, Pixel2 = SplitByte(Byte)
                            
                            thisRow[x] = palette[Pixel1]
                            thisRow[x + 1] = palette[Pixel2]
                        end
                        local FinalByte = ThisStream:ReadByte() -- Get the final byte
                        thisRow[BitmapWidth] = palette[SplitByte(FinalByte)] -- Add just the first pixel to the row
                    end
                    
                    ThisStream:Advance(padAmount) -- Advance the extra padding amount
                    pixels[y] = thisRow 
                end
                
                self.PaletteData = palette
                self.PixelData = pixels 
                
                return self
                
            elseif ( HeaderInfo.BitDepth == 8 ) then 
                -- 8 bits per pixel
                -- Refer to my comments in bitdepth 4, 
                -- they (mostly) apply here too
                
                local palette = {} 
                
                for i = 1, HeaderInfo.PaletteEntries do 
                    
                    local B = ThisStream:ReadByte()
                    local G = ThisStream:ReadByte()
                    local R = ThisStream:ReadByte()
                    ThisStream:Advance(1)
                    
                    palette[i - 1] = Color4.fromBGRA(B, G, R, 0xFF)
                end
                
                local pixels = {}
                
                for y = HeaderInfo.BitmapHeight, 1, -1 do 
                    local thisRow = {}
                    
                    for x = 1, HeaderInfo.BitmapWidth do 
                        local thisIndex = ThisStream:ReadByte() -- This pixel's palette index
                        local thisPixel = palette[thisIndex] -- The proper color for this pixel
                        
                        thisRow[x] = thisPixel
                    end
                    
                    pixels[y] = thisRow 
                    
                    ThisStream:Advance(1) -- Extra padding byte or some shit
                end
                
                self.PaletteData = palette
                self.PixelData = pixels 
                
                return self
                
            elseif ( HeaderInfo.BitDepth == 24 ) then
                -- Same as 8 bits per pixel, minus the palette
                
                -- Setup a 2d array of pixels
                local pixels = {}
                
                local pixelPad = HeaderInfo.BitmapWidth % 4
                
                -- Loop through pixels and insert them
                for y = HeaderInfo.BitmapHeight, 1, -1 do 
                    local thisRow = {}
                    
                    for x = 1, HeaderInfo.BitmapWidth do 
                        local B = ThisStream:ReadByte() -- Blue
                        local G = ThisStream:ReadByte() -- Green
                        local R = ThisStream:ReadByte() -- Red

                        local thisPixel = Color4.fromBGRA(B, G, R, 0xFF)
                        
                        thisRow[x] = thisPixel
                    end
                    
                    pixels[y] = thisRow 
                    
                    -- For some reason 24 bit bitmaps
                    -- have extra padding, calculated by width % 4
                    -- I haven't found a single mention of this anywhere, but it exists 
                    
                    if ( pixelPad > 0 ) then 
                        ThisStream:Advance(pixelPad)
                    end
                end
                
                self.PaletteData = palette
                self.PixelData = pixels 
                
                return self
            end
            
            
        elseif ( HeaderInfo.CompressType == 3 and HeaderInfo.HeaderType == 'BITMAPV5HEADER' ) then -- 32 bit support
            if ( HeaderInfo.BitDepth ~= 32 ) then
                warn('Expected a bit depth of 32 for a BITMAPV5HEADER bitmap. Parsing may be done incorrectly!')
            end 
            
            
            -- Pretty sure these go unused. Even if they're meant to be used,
            -- they still won't be used in this parser anyways
            ThisStream:Advance(4) -- Red mask
            ThisStream:Advance(4) -- Green mask
            ThisStream:Advance(4) -- Blue mask
            ThisStream:Advance(4) -- Alpha mask

            
            local ColorSpaceSignature = ThisStream:ReadInt(4) -- Good luck finding any docs about this shit (something to do with LCS_WINDOWS_COLOR_SPACE)
            if ( ColorSpaceSignature ~= 1466527264 and ColorSpaceSignature ~= 1111970419 ) then
                return error(errorFormat:format('Bitmap:Parse', 'Unsupported color space'), 2)
            end
            
            -- After the color signature bullshit theres apparently a bunch
            -- of unused values, the size of which depend on whatever encoder
            -- / decoder you're using.
            -- So for compatibility, just skip ahead to the color section.
            
            ThisStream:SeekTo(HeaderInfo.ImageOffset + 1)
            
            
            -- DECODE TIME 
            -- Unlike 4, 8, and 24, this is extremely straightforward
            
            -- 2d array like earlier
            local pixels = {}
                        
            -- Loop through pixels and insert them
            for y = HeaderInfo.BitmapHeight, 1, -1 do 
                local thisRow = {}
                
                for x = 1, HeaderInfo.BitmapWidth do 
                    local B = ThisStream:ReadByte() -- Blue
                    local G = ThisStream:ReadByte() -- Green
                    local R = ThisStream:ReadByte() -- Red
                    local A = ThisStream:ReadByte() -- Alpha
                    
                    local thisPixel = Color4.fromBGRA(B, G, R, A)
                    
                    thisRow[x] = thisPixel
                end
                
                pixels[y] = thisRow 
                
                -- No padding :money_mouth:
            end
            
            self.PaletteData = palette
            self.PixelData = pixels 
            
            return self
        else
            ThisStream:Destroy()
            return error(errorFormat:format('Bitmap:Parse', 'This compression method is unsupported'), 2) 
        end
        
        return self 
    end
    
    function Bitmap:GetPixels() 
        return self.PixelData
    end

    function Bitmap:GetResolution() 
        return Vector2.new(self.BitmapWidth, self.BitmapHeight)
    end
    
    function Bitmap:Destroy() 
        self.Stream:Destroy()
        self.HeaderInfo = 0 
        self.PixelData = nil 
        setmetatable(self, nil)
    end
end

return Bitmap 
