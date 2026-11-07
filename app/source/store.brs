' What b0r3d TV keeps on the TV between runs: the last two channels opened (for LAST and for
' landing on the last one) and the screen size picked with Play.

function RegRead(key as string, fallback as string) as string
    sec = CreateObject("roRegistrySection", "b0r3dtv")
    if sec.Exists(key) then return sec.Read(key)
    return fallback
end function

sub RegWrite(key as string, value as string)
    sec = CreateObject("roRegistrySection", "b0r3dtv")
    sec.Write(key, value)
    sec.Flush()
end sub
