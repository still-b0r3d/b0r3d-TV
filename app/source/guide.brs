' The late-night cable guide look: a preview window, the focused channel's details,
' a grid of channels and a bar of remote hints, on a 1280 x 720 screen.

function GuideColors() as object
    return {
        bg: &h0A1640FF,
        tile: &h0D1D52FF,
        frame: &hC9D6FFFF,
        text: &hEEF3FFFF,
        soft: &hC9D6FFFF,
        white: &hFFFFFFFF,
        accent: &hFFD23FFF,
        ink: &h0A1640FF,
        cell1: &h173A9CFF,
        cell2: &h1D46B8FF,
        cell3: &h122F86FF,
        bar: &h06102EFF
    }
end function

function GuideFonts() as object
    reg = CreateObject("roFontRegistry")
    return {
        logo: reg.GetDefaultFont(46, true, false),
        badge: reg.GetDefaultFont(24, true, false),
        clock: reg.GetDefaultFont(44, true, false),
        small: reg.GetDefaultFont(20, false, false),
        num: reg.GetDefaultFont(64, true, false),
        sign: reg.GetDefaultFont(56, true, false),
        name: reg.GetDefaultFont(32, true, false),
        body: reg.GetDefaultFont(23, false, false),
        bold: reg.GetDefaultFont(23, true, false),
        cellNum: reg.GetDefaultFont(30, true, false),
        cell: reg.GetDefaultFont(26, true, false),
        cellText: reg.GetDefaultFont(24, false, false),
        head: reg.GetDefaultFont(20, true, false),
        big: reg.GetDefaultFont(96, true, false),
        bar: reg.GetDefaultFont(21, true, false)
    }
end function

sub DrawGuide(st as object)
    s = st.screen
    f = st.fonts
    k = GuideColors()
    ch = st.channels[st.focus]
    s.Clear(k.bg)

    ' The preview window shows the focused channel.
    DrawFrame(s, 40, 30, 520, 292, 4, k.frame)
    s.DrawRect(44, 34, 512, 284, k.tile)
    DrawPreview(st, ch, 44, 34, 512, 284)

    ' The details of the focused channel, the logo and the clock.
    x = 592
    s.DrawText("b0r3d", x, 30, k.white, f.logo)
    bx = x + f.logo.GetOneLineWidth("b0r3d", 600) + 12
    s.DrawRect(bx, 42, 52, 32, k.accent)
    DrawCentered(s, "TV", bx, 42, 52, 32, k.ink, f.badge)
    DrawRight(s, st.clock.time, 1240, 30, k.white, f.clock)
    DrawRight(s, st.clock.date, 1240, 80, k.soft, f.small)
    s.DrawText(ch.n, x, 112, k.accent, f.num)
    s.DrawText(ch.sign, x + f.num.GetOneLineWidth(ch.n, 600) + 18, 118, k.white, f.sign)
    s.DrawText(ch.name, x, 192, k.text, f.name)
    s.DrawText(ch.now, x, 236, k.soft, f.body)
    s.DrawText(ch.hint, x, 282, k.accent, f.bold)
    DrawSprite(s, RukusLoaf(), RukusColors(), 1240 - 16 * 7, 322 - 9 * 7, 7)

    ' The grid: a header, then one row per channel.
    gx = 40
    gy = 340
    s.DrawRect(gx, gy, 96, 34, k.frame)
    s.DrawRect(gx + 100, gy, 170, 34, k.frame)
    s.DrawRect(gx + 274, gy, 926, 34, k.frame)
    DrawCentered(s, "CH", gx, gy, 96, 34, k.ink, f.head)
    DrawMiddle(s, "CALL", gx + 114, gy, 34, k.ink, f.head)
    DrawMiddle(s, "ON NOW · " + st.clock.time, gx + 290, gy, 34, k.ink, f.head)
    y = gy + 38
    for i = 0 to st.channels.Count() - 1
        row = st.channels[i]
        fg = k.text
        b1 = k.cell1
        b2 = k.cell2
        b3 = k.cell3
        if i = st.focus then
            fg = k.ink
            b1 = k.accent
            b2 = k.accent
            b3 = k.accent
        end if
        s.DrawRect(gx, y, 96, 44, b1)
        s.DrawRect(gx + 100, y, 170, 44, b2)
        s.DrawRect(gx + 274, y, 926, 44, b3)
        DrawCentered(s, row.n, gx, y, 96, 44, fg, f.cellNum)
        DrawMiddle(s, row.sign, gx + 114, y, 44, fg, f.cell)
        DrawMiddle(s, row.now, gx + 290, y, 44, fg, f.cellText)
        y = y + 48
    end for

    ' What just happened, or how to use this test build.
    if st.note <> "" then
        s.DrawText(st.note, gx, y + 22, k.white, f.bold)
    else
        s.DrawText("Test build 0.1: press OK on a channel to try it.", gx, y + 22, k.soft, f.body)
    end if

    ' The bar of remote hints, and the version.
    s.DrawRect(0, 668, 1280, 52, k.bar)
    DrawArrowUp(s, 52, 685, k.white)
    DrawArrowDown(s, 78, 685, k.white)
    hx = DrawRun(s, 100, 682, "MOVE", k.soft, f.bar, 28)
    hx = DrawRun(s, hx, 682, "OK", k.white, f.bar, 8)
    hx = DrawRun(s, hx, 682, "TUNE IN", k.soft, f.bar, 28)
    hx = DrawRun(s, hx, 682, "BACK", k.white, f.bar, 8)
    hx = DrawRun(s, hx, 682, "LEAVE", k.soft, f.bar, 0)
    DrawRight(s, st.version, 1240, 682, k.soft, f.bar)

    s.SwapBuffers()
end sub

' The preview of the focused channel: its call sign and what OK does.
sub DrawPreview(st as object, ch as object, x as integer, y as integer, w as integer, h as integer)
    f = st.fonts
    k = GuideColors()
    DrawCentered(st.screen, ch.sign, x, y + 56, w, 110, k.white, f.big)
    DrawCentered(st.screen, ch.hint, x, y + 190, w, 32, k.soft, f.body)
end sub

sub DrawFrame(s as object, x as integer, y as integer, w as integer, h as integer, t as integer, color as dynamic)
    s.DrawRect(x, y, w, t, color)
    s.DrawRect(x, y + h - t, w, t, color)
    s.DrawRect(x, y, t, h, color)
    s.DrawRect(x + w - t, y, t, h, color)
end sub

sub DrawArrowUp(s as object, cx as integer, y as integer, color as dynamic)
    for i = 0 to 7
        s.DrawRect(cx - i, y + i * 2, i * 2 + 1, 2, color)
    end for
end sub

sub DrawArrowDown(s as object, cx as integer, y as integer, color as dynamic)
    for i = 0 to 7
        s.DrawRect(cx - 7 + i, y + i * 2, 15 - i * 2, 2, color)
    end for
end sub

sub DrawCentered(s as object, text as string, x as integer, y as integer, w as integer, h as integer, color as dynamic, font as object)
    tw = font.GetOneLineWidth(text, 4000)
    th = font.GetOneLineHeight()
    s.DrawText(text, x + (w - tw) \ 2, y + (h - th) \ 2, color, font)
end sub

sub DrawMiddle(s as object, text as string, x as integer, y as integer, h as integer, color as dynamic, font as object)
    th = font.GetOneLineHeight()
    s.DrawText(text, x, y + (h - th) \ 2, color, font)
end sub

sub DrawRight(s as object, text as string, rx as integer, y as integer, color as dynamic, font as object)
    s.DrawText(text, rx - font.GetOneLineWidth(text, 4000), y, color, font)
end sub

' Draws one piece of text and returns where the next one starts.
function DrawRun(s as object, x as integer, y as integer, text as string, color as dynamic, font as object, gap as integer) as integer
    s.DrawText(text, x, y, color, font)
    return x + font.GetOneLineWidth(text, 4000) + gap
end function
