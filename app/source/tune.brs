' Tuning in: when OK opens a channel, a short burst of TV static with the channel's banner on
' top, and a crackle of static from the speakers (when Sound is on). Then the app opens.

function LoadTuneSound() as dynamic
    sound = invalid
    try
        sound = CreateObject("roAudioResource", "pkg:/sounds/tune.wav")
    catch e
        sound = invalid
    end try
    return sound
end function

sub PlayTuneSound(st as object)
    if st.tuneSound <> invalid then st.tuneSound.Trigger(65)
end sub

sub TuneIn(st as object, ch as object)
    if st.sound then PlayTuneSound(st)
    timer = CreateObject("roTimespan")
    st.tuneTimer = timer
    while timer.TotalMilliseconds() < 450
        DrawStatic(st, ch)
    end while
end sub

' One frame of static: rows of random grey streaks in the look's colours, then the banner.
sub DrawStatic(st as object, ch as object)
    s = st.screen
    levels = st.kit.noise
    rows = 36
    rowH = st.h \ rows
    unit = st.w \ 48
    for r = 0 to rows - 1
        y = r * rowH
        x = 0
        while x < st.w
            w = unit * Rnd(6)
            s.DrawRect(x, y, w, rowH, levels[Rnd(4) - 1])
            x = x + w
        end while
    end for
    DrawTuneBanner(st, ch)
    s.SwapBuffers()
end sub

' The channel banner over the static, in the look's style.
sub DrawTuneBanner(st as object, ch as object)
    s = st.screen
    f = st.fonts
    c = st.kit
    k = st.k
    if st.look = "b95" then
        DrawB95Banner(st, ch)
    else if st.look = "phosphor" then
        text = "TUNING :: CH " + ch.n + " :: " + ch.sign
        w = f.banner.GetOneLineWidth(text, 99999) + Z(48, k)
        h = f.banner.GetOneLineHeight() + Z(32, k)
        x = (st.w - w) \ 2
        y = (st.h - h) \ 2
        s.DrawRect(x, y, w, h, c.bg)
        DrawFrame(s, x, y, w, h, Z(2, k), c.full)
        DrawGlow(s, text, x + Z(24, k), y + Z(16, k), c.full, c.glow, f.banner, Z(1, k))
    else if st.look = "vcr" then
        DrawVcrChannel(st, ch, Z(26, k))
    else
        ' A cable box's channel banner: number and call sign over "tuning in".
        x = Z(820, k)
        y = Z(40, k)
        w = Z(1240, k) - x
        h = Z(176, k) - y
        s.DrawRect(x, y, w, h, c.bg)
        DrawFrame(s, x, y, w, h, Z(4, k), c.frame)
        nx = x + Z(24, k)
        ny = y + Z(14, k)
        s.DrawText(ch.n, nx, ny, c.accent, f.num)
        sx = nx + f.num.GetOneLineWidth(ch.n, 99999) + Z(18, k)
        s.DrawText(ch.sign, sx, ny + f.num.GetAscent() - f.sign.GetAscent(), c.white, f.sign)
        s.DrawText(TrimToWidth("TUNING IN " + UCase(ch.name), f.banner, w - Z(48, k)), nx, ny + f.num.GetOneLineHeight() + Z(6, k), c.soft, f.banner)
    end if
end sub
