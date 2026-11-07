' A small test screensaver: Rukus loafing next to the time, on black. It moves to a new spot
' every minute so nothing stays in one place. The real one comes in step D.

sub RunScreenSaver()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roScreen", true, 1280, 720)
    screen.SetMessagePort(port)
    screen.SetAlphaEnable(true)
    reg = CreateObject("roFontRegistry")
    reg.Register("pkg:/fonts/vt323/VT323-Regular.ttf")
    big = reg.GetFont("VT323", 72, false, false)
    if big = invalid then big = reg.GetDefaultFont(48, false, false)
    small = reg.GetFont("VT323", 30, false, false)
    if small = invalid then small = reg.GetDefaultFont(24, false, false)
    x = 460
    y = 250
    moved = CreateObject("roTimespan")
    while true
        if moved.TotalSeconds() >= 60 then
            x = 40 + Rnd(1280 - 80 - 360)
            y = 40 + Rnd(720 - 80 - 240)
            moved.Mark()
        end if
        DrawSaver(screen, big, small, x, y)
        wait(1000, port)
    end while
end sub

sub DrawSaver(screen as object, big as object, small as object, x as integer, y as integer)
    screen.Clear(&h000000FF)
    DrawSprite(screen, RukusLoaf(), RukusColors(), x, y, 10)
    screen.DrawText(ClockNow().time, x, y + 110, &hC9D6FFFF, big)
    screen.DrawText("b0r3d TV", x, y + 190, &h5C5C66FF, small)
    screen.SwapBuffers()
end sub
