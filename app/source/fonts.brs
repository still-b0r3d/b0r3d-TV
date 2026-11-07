' The fonts: Barlow Condensed in four weights and VT323, both free under the SIL Open Font
' License (each folder in fonts/ carries its OFL.txt). Roku's own font stands in for any that
' doesn't load.

function RegisterFonts() as object
    reg = CreateObject("roFontRegistry")
    for each file in FontFiles()
        if not reg.Register(file) then print "b0r3d TV: could not load the font "; file
    end for
    return reg
end function

function FontFiles() as object
    return [
        "pkg:/fonts/barlow-condensed/BarlowCondensed-Medium.ttf",
        "pkg:/fonts/barlow-condensed/BarlowCondensed-SemiBold.ttf",
        "pkg:/fonts/barlow-condensed/BarlowCondensed-Bold.ttf",
        "pkg:/fonts/barlow-condensed/BarlowCondensed-ExtraBold.ttf",
        "pkg:/fonts/vt323/VT323-Regular.ttf"
    ]
end function

' The family names the TV really registered. Roku can say yes to a file it didn't load, so
' every font is looked up by these names.
function FontFamilies(reg as object) as object
    names = []
    try
        for each name in reg.GetFamilies()
            names.Push(name)
        end for
    catch e
        print "b0r3d TV: could not list the fonts: "; e.message
    end try
    return names
end function

' Barlow Condensed in one of its weights: medium, semibold, bold or extrabold. Each weight
' registers as its own family, except Bold, which is the family's bold face.
function Barlow(st as object, weight as string, size as integer) as object
    heavy = (weight = "bold" or weight = "extrabold")
    family = "Barlow Condensed"
    bold = true
    if weight = "medium" then
        family = "Barlow Condensed Medium"
        bold = false
    else if weight = "semibold" then
        family = "Barlow Condensed SemiBold"
        bold = false
    else if weight = "extrabold" then
        family = "Barlow Condensed ExtraBold"
        bold = false
    end if
    font = FontOf(st, family, size, bold)
    if font = invalid then font = FontOf(st, "Barlow Condensed", size, heavy)
    if font = invalid then font = st.fontReg.GetDefaultFont(size, heavy, false)
    return font
end function

function Vt323(st as object, size as integer) as object
    font = FontOf(st, "VT323", size, false)
    if font = invalid then font = st.fontReg.GetDefaultFont(size, false, false)
    return font
end function

function FontOf(st as object, family as string, size as integer, bold as boolean) as dynamic
    if not HasName(st.families, family) then return invalid
    return st.fontReg.GetFont(family, size, bold, false)
end function

function HasName(list as object, name as string) as boolean
    for each item in list
        if LCase(item) = LCase(name) then return true
    end for
    return false
end function
