' The screen: 1920 x 1080 when asked for and the TV allows it, else 1280 x 720. The looks are
' laid out on a 1280 x 720 grid and scaled by st.k (1.5 at 1920 x 1080), so text is drawn at
' the TV's own size instead of being stretched afterwards.

sub OpenScreen(st as object, want as string)
    st.screen = invalid
    st.fonts = invalid
    screen = invalid
    st.fhdRefused = false
    st.fhdHow = ""
    if want = "fhd" then
        ' The documented way first: a screen without a size matches the TV's menus when the
        ' manifest lists their size. Then the undocumented one: asking for 1920 x 1080.
        screen = TryScreen(0, 0)
        if screen <> invalid then
            if screen.GetWidth() < 1920 then screen = invalid
        end if
        if screen <> invalid then
            st.fhdHow = "matches the TV"
        else
            screen = TryScreen(1920, 1080)
            if screen <> invalid then st.fhdHow = "asked for"
        end if
        if screen = invalid then st.fhdRefused = true
    end if
    if screen = invalid then screen = CreateObject("roScreen", true, 1280, 720)
    screen.SetMessagePort(st.port)
    screen.SetAlphaEnable(true)
    st.screen = screen
    st.w = screen.GetWidth()
    st.h = screen.GetHeight()
    st.k = st.w / 1280
    st.res = "hd"
    if st.w >= 1920 then st.res = "fhd"
    st.fonts = GuideFonts(st)
end sub

' Play flips between the two sizes, to see which looks sharper on the TV. The pick is kept.
sub FlipSharpness(st as object)
    want = "fhd"
    if st.res = "fhd" then want = "hd"
    OpenScreen(st, want)
    RegWrite("res", want)
    if want = "fhd" and st.res <> "fhd" then
        st.note = "This TV said no to 1920 x 1080, so it stays 1280 x 720."
    else
        st.note = "Now " + st.w.ToStr() + " x " + st.h.ToStr() + ". Play flips back."
    end if
    st.noteTimer = invalid
    Redraw(st)
end sub

' A double-buffered screen of that size (0 x 0: the TV's own size), or invalid.
function TryScreen(w as integer, h as integer) as dynamic
    screen = invalid
    try
        if w = 0 then
            screen = CreateObject("roScreen", true)
        else
            screen = CreateObject("roScreen", true, w, h)
        end if
    catch e
        screen = invalid
    end try
    return screen
end function

' A spot on the 1280 x 720 layout, scaled to the real screen.
function Z(v as dynamic, k as dynamic) as integer
    return Int(v * k + 0.5)
end function
