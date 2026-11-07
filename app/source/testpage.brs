' The test page (the options key): what this TV allows, for planning the next steps.

sub DrawTestPage(st as object)
    s = st.screen
    f = st.fonts
    c = GuideColors()
    k = st.k
    s.Clear(c.bg)
    left = Z(40, k)
    right = Z(1240, k)
    bandY = Z(24, k)
    bandH = Z(80, k) - bandY
    s.DrawRect(left, bandY, right - left, bandH, c.frame)
    DrawMiddleSpaced(s, "TV CHECK", left + Z(16, k), bandY, bandH, c.ink, f.pageTitle, Z(2, k))
    DrawRight(s, st.version, right - Z(16, k), bandY + (bandH - f.barNum.GetOneLineHeight()) \ 2, c.ink, f.barNum)

    labelX = left + Z(16, k)
    valueX = Z(300, k)
    valueW = right - valueX - Z(16, k)
    stepY = f.pageValue.GetOneLineHeight() + Z(5, k)
    labelDrop = (stepY - f.pageLabel.GetOneLineHeight()) \ 2
    y = Z(96, k)
    bottom = Z(656, k)
    for each line in AllAnswers(st)
        if y + stepY <= bottom then s.DrawText(line.label, labelX, y + labelDrop, c.soft, f.pageLabel)
        for each part in WrapText(line.value, f.pageValue, valueW)
            if y + stepY <= bottom then s.DrawText(TrimToWidth(part, f.pageValue, valueW), valueX, y, c.white, f.pageValue)
            y = y + stepY
        end for
        y = y + Z(3, k)
    end for

    ' The bar: how to get back.
    top = Z(668, k)
    s.DrawRect(0, top, st.w, st.h - top, c.bar)
    ty = top + (st.h - top - f.bar.GetOneLineHeight()) \ 2
    mid = top + (st.h - top) \ 2
    sp = Z(1, k)
    hx = DrawRun(s, left, ty, "BACK", c.white, f.bar, sp, Z(14, k))
    hx = DrawRun(s, hx, ty, "GUIDE", c.soft, f.bar, sp, Z(32, k))
    DrawPlay(s, hx, mid, Z(16, k), c.white)
    hx = hx + Z(14, k) + Z(14, k)
    DrawRun(s, hx, ty, "1280 X 720 OR 1920 X 1080", c.soft, f.bar, sp, 0)
    s.SwapBuffers()
end sub
