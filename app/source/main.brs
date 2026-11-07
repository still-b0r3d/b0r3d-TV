' b0r3d TV: a home screen for Roku TVs that looks like an old cable box.
' Everything is drawn on one 2D screen, 1280 x 720.

sub Main(args as dynamic)
    screen = CreateObject("roScreen", true, 1280, 720)
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetAlphaEnable(true)

    st = {
        screen: screen,
        fonts: GuideFonts(),
        channels: GuideChannels(),
        focus: 0,
        note: "",
        noteTimer: invalid,
        clock: ClockNow(),
        version: AppVersionLine()
    }
    print "b0r3d TV "; st.version; " started"
    DrawGuide(st)

    while true
        msg = wait(1000, port)
        if msg = invalid then
            redraw = false
            now = ClockNow()
            if now.minute <> st.clock.minute then
                st.clock = now
                redraw = true
            end if
            if st.noteTimer <> invalid then
                if st.noteTimer.TotalMilliseconds() > 4000 then
                    st.note = st.note + " Nothing yet: if this stays, the TV didn't open it."
                    st.noteTimer = invalid
                    redraw = true
                end if
            end if
            if redraw then DrawGuide(st)
        else if type(msg) = "roUniversalControlEvent" then
            code = msg.GetInt()
            if code = 0 then
                exit while
            else if code = 2 then
                MoveFocus(st, -1)
            else if code = 3 then
                MoveFocus(st, 1)
            else if code = 6 then
                OpenChannel(st)
            end if
        end if
    end while
end sub

' Up and down move the highlight; it stops at the first and last row.
sub MoveFocus(st as object, delta as integer)
    n = st.focus + delta
    if n < 0 then n = 0
    if n > st.channels.Count() - 1 then n = st.channels.Count() - 1
    if n <> st.focus then
        st.focus = n
        st.note = ""
        st.noteTimer = invalid
        DrawGuide(st)
    end if
end sub

' OK opens the highlighted channel's app through the Roku's app manager. Roku TVs don't let
' an app switch the TV's inputs, so inputs stay on Roku's own home screen.
sub OpenChannel(st as object)
    ch = st.channels[st.focus]
    st.note = "Opening " + ch.name + "..."
    st.noteTimer = CreateObject("roTimespan")
    DrawGuide(st)
    print "b0r3d TV: opening "; ch.id
    try
        apps = CreateObject("roAppManager")
        apps.LaunchApp(ch.id, "", {})
    catch e
        print "b0r3d TV: the TV refused "; ch.id; ": "; e.message
        st.note = "The TV refused to open " + ch.name + ": " + e.message
        st.noteTimer = invalid
        DrawGuide(st)
    end try
end sub

' The channels in this test build: just YouTube for now.
function GuideChannels() as object
    list = [
        { n: "01", sign: "YTUBE", name: "YouTube", now: "YouTube", id: "837", hint: "OK opens YouTube" }
    ]
    apps = CreateObject("roAppManager")
    for each ch in list
        found = false
        try
            found = apps.IsAppInstalled(ch.id, "")
        catch e
            print "b0r3d TV: could not ask whether "; ch.name; " is installed: "; e.message
        end try
        print "b0r3d TV: "; ch.name; " installed: "; found
        if not found then ch.now = ch.now + " (not found on this TV)"
    end for
    return list
end function

' "v0.1 · Build: dev": the version from the manifest, the build from BuildStamp().
function AppVersionLine() as string
    info = CreateObject("roAppInfo")
    return "v" + info.GetValue("major_version") + "." + info.GetValue("minor_version") + " · Build: " + BuildStamp()
end function

' The time and date for the guide, in the TV's own time zone.
function ClockNow() as object
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    hours = dt.GetHours()
    mins = dt.GetMinutes()
    half = "AM"
    if hours >= 12 then half = "PM"
    h12 = hours mod 12
    if h12 = 0 then h12 = 12
    mm = mins.ToStr()
    if mins < 10 then mm = "0" + mm
    days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    return {
        time: h12.ToStr() + ":" + mm + " " + half,
        date: days[dt.GetDayOfWeek()] + " " + months[dt.GetMonth() - 1] + " " + dt.GetDayOfMonth().ToStr(),
        minute: hours * 60 + mins
    }
end function
