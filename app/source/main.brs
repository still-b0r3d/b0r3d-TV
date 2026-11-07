' b0r3d TV: a home screen for Roku TVs that looks like an old cable box.
' Everything is drawn on one 2D screen: 1920 x 1080 where the TV allows it, else 1280 x 720.

sub Main(args as dynamic)
    st = {
        port: CreateObject("roMessagePort"),
        mode: "guide",
        note: "",
        noteName: "",
        noteTimer: invalid,
        clock: ClockNow(),
        version: AppVersionLine()
    }
    st.fontReg = RegisterFonts()
    st.families = FontFamilies(st.fontReg)
    st.built = BuildChannels()
    st.channels = st.built.list
    st.focus = StartFocus(st.channels)
    st.answers = TvAnswers(st)
    OpenScreen(st, RegRead("res", "fhd"))
    print "b0r3d TV "; st.version; " started at "; st.w; " x "; st.h; " with "; st.channels.Count(); " channels"
    PrintAnswers(st)
    Redraw(st)

    while true
        msg = wait(1000, st.port)
        if msg = invalid then
            Tick(st)
        else if type(msg) = "roUniversalControlEvent" then
            code = msg.GetInt()
            if code < 100 then
                if not HandleKey(st, code) then exit while
            end if
        end if
    end while
end sub

' One key press. Returns false when b0r3d TV should close.
function HandleKey(st as object, code as integer) as boolean
    if st.mode = "test" then
        if code = 0 or code = 10 then
            st.mode = "guide"
            Redraw(st)
        else if code = 13 then
            FlipSharpness(st)
        end if
        return true
    end if
    if code = 0 then
        return false
    else if code = 2 then
        MoveFocus(st, -1)
    else if code = 3 then
        MoveFocus(st, 1)
    else if code = 8 then
        MoveFocus(st, -GuideRows())
    else if code = 9 then
        MoveFocus(st, GuideRows())
    else if code = 7 then
        JumpLast(st)
    else if code = 6 then
        OpenChannel(st)
    else if code = 10 then
        st.mode = "test"
        PrintAnswers(st)
        Redraw(st)
    else if code = 13 then
        FlipSharpness(st)
    end if
    return true
end function

' The test page's answers, in the app log too.
sub PrintAnswers(st as object)
    for each line in AllAnswers(st)
        print "b0r3d TV check: "; line.label; ": "; line.value
    end for
end sub

' Up and down move the highlight one row; Rewind and Fast-forward a page. It stops at the ends.
sub MoveFocus(st as object, delta as integer)
    count = st.channels.Count()
    if count = 0 then return
    n = st.focus + delta
    if n < 0 then n = 0
    if n > count - 1 then n = count - 1
    if n <> st.focus then
        st.focus = n
        st.note = ""
        st.noteTimer = invalid
        Redraw(st)
    end if
end sub

' LAST (Replay) jumps between the two channels opened most recently, like a cable remote's LAST key.
sub JumpLast(st as object)
    last = RegRead("last", "")
    prev = RegRead("prev", "")
    target = last
    if st.channels.Count() > 0 then
        if st.channels[st.focus].id = last then target = prev
    end if
    i = IndexOfId(st.channels, target)
    if i < 0 and target = last then i = IndexOfId(st.channels, prev)
    if i < 0 then
        st.note = "LAST jumps between the last two channels you opened."
    else
        st.focus = i
        st.note = ""
    end if
    st.noteTimer = invalid
    Redraw(st)
end sub

' OK opens the highlighted channel's app through the Roku's app manager. It's remembered first,
' because b0r3d TV closes as the other app opens.
sub OpenChannel(st as object)
    if st.channels.Count() = 0 then return
    ch = st.channels[st.focus]
    RememberOpened(ch.id)
    st.note = "Opening " + ch.name + "..."
    st.noteName = ch.name
    st.noteTimer = CreateObject("roTimespan")
    Redraw(st)
    print "b0r3d TV: opening "; ch.id
    try
        apps = CreateObject("roAppManager")
        apps.LaunchApp(ch.id, "", {})
    catch e
        print "b0r3d TV: the TV refused "; ch.id; ": "; e.message
        st.note = "The TV refused to open " + ch.name + ": " + e.message
        st.noteTimer = invalid
        Redraw(st)
    end try
end sub

' Once a second: the clock moves on, a channel that didn't open says so, and the screen is
' drawn again, since Roku's own screensaver can wipe it while b0r3d TV is open.
sub Tick(st as object)
    st.clock = ClockNow()
    if st.noteTimer <> invalid then
        if st.noteTimer.TotalMilliseconds() > 4000 then
            st.note = "Nothing yet: the TV didn't open " + st.noteName + "."
            st.noteTimer = invalid
        end if
    end if
    Redraw(st)
end sub

sub Redraw(st as object)
    if st.mode = "test" then
        DrawTestPage(st)
    else
        DrawGuide(st)
    end if
end sub

' The highlight starts on the channel opened last, so coming back lands where you left.
function StartFocus(channels as object) as integer
    i = IndexOfId(channels, RegRead("last", ""))
    if i < 0 then return 0
    return i
end function

function IndexOfId(channels as object, id as string) as integer
    if id = "" then return -1
    for i = 0 to channels.Count() - 1
        if channels[i].id = id then return i
    end for
    return -1
end function

sub RememberOpened(id as string)
    last = RegRead("last", "")
    if last = id then return
    if last <> "" then RegWrite("prev", last)
    RegWrite("last", id)
end sub

' "v0.15 · Build: dev": the version from the manifest, the build from BuildStamp().
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
