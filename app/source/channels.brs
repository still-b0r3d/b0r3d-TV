' Which channels the guide shows. b0r3d TV first asks the TV for its whole app list (a call
' Roku doesn't document). If the TV won't say, it goes through its own list of known apps one
' by one and keeps the installed ones. TV inputs never become channels; screensaver apps are
' channels that start hidden. Settings then puts them in the owner's order and hides or shows
' each one (ApplyChannelPrefs).

function BuildChannels() as object
    known = {}
    for each app in KnownApps()
        known[app.id] = app
    end for
    out = { list: [], source: "" }
    am = CreateObject("roAppManager")
    tvApps = invalid
    try
        tvApps = am.GetAppList()
    catch e
        tvApps = invalid
    end try
    if type(tvApps) = "roArray" then
        for each entry in tvApps
            item = AppEntry(entry)
            if item <> invalid then
                ' Where the TV says what kind of app it is, keep apps ("appl") and screensavers.
                kind = LCase(item.kind)
                if kind <> "" and kind <> "appl" and kind <> "ssvr" then item = invalid
            end if
            if item <> invalid then
                app = known[item.id]
                if app <> invalid then
                    out.list.Push(MakeChannel(item.id, app.name, app.sign, Tagline(item.title, app.name), app.kind))
                else if not IsTvInput(item.id) and item.id <> "dev" then
                    name = ShortTitle(item.title)
                    if name = "" then name = "App " + item.id
                    kind = "app"
                    if LCase(item.kind) = "ssvr" then kind = "saver"
                    out.list.Push(MakeChannel(item.id, name, MakeSign(name), Tagline(item.title, name), kind))
                end if
            end if
        end for
        if out.list.Count() > 0 then out.source = "the TV's own app list"
    end if
    if out.list.Count() = 0 then
        for each app in KnownApps()
            if IsInstalled(am, app.id) then out.list.Push(MakeChannel(app.id, app.name, app.sign, app.name, app.kind))
        end for
        out.source = "b0r3d TV's list of known apps"
    end if
    return out
end function

function MakeChannel(id as string, name as string, sign as string, now as string, kind as string) as object
    return { id: id, name: name, sign: sign, now: now, kind: kind, n: "", shown: true }
end function

' Puts the channels in the saved order (new apps go at the end), marks which are shown, and
' numbers the shown ones 01, 02... The highlight stays on the same channel where it can.
sub ApplyChannelPrefs(st as object)
    focusId = ""
    if st.DoesExist("channels") then
        if st.channels.Count() > 0 and st.focus < st.channels.Count() then focusId = st.channels[st.focus].id
    end if
    st.all = InOrder(st.built.list, RegRead("order", ""))
    vis = ReadVisibility()
    st.channels = []
    for each c in st.all
        c.n = "--"
        c.shown = (c.kind = "app")
        if vis.DoesExist(c.id) then c.shown = vis[c.id]
        if c.shown then st.channels.Push(c)
    end for
    for i = 0 to st.channels.Count() - 1
        st.channels[i].n = TwoDigits(i + 1)
    end for
    i = IndexOfId(st.channels, focusId)
    if i >= 0 then
        st.focus = i
    else if not st.DoesExist("focus") then
        st.focus = 0
    end if
    if st.focus > st.channels.Count() - 1 then st.focus = st.channels.Count() - 1
    if st.focus < 0 then st.focus = 0
end sub

function InOrder(list as object, saved as string) as object
    out = []
    taken = {}
    if saved <> "" then
        for each id in saved.Split(",")
            for each c in list
                if c.id = id and not taken.DoesExist(id) then
                    out.Push(c)
                    taken[id] = true
                end if
            end for
        end for
    end if
    for each c in list
        if not taken.DoesExist(c.id) then out.Push(c)
    end for
    return out
end function

' Which channels the owner showed or hid: "837:1,123095:0,...".
function ReadVisibility() as object
    vis = {}
    saved = RegRead("vis", "")
    if saved = "" then return vis
    for each pair in saved.Split(",")
        parts = pair.Split(":")
        if parts.Count() = 2 then vis[parts[0]] = (parts[1] = "1")
    end for
    return vis
end function

sub SaveChannelPrefs(st as object)
    order = ""
    vis = ""
    for each c in st.all
        if order <> "" then
            order = order + ","
            vis = vis + ","
        end if
        order = order + c.id
        vis = vis + c.id + ":" + OnOff(c.shown)
    end for
    RegWrite("order", order)
    RegWrite("vis", vis)
end sub

' One entry of the TV's app list, as { id, title, kind }, whatever shape the TV hands over.
function AppEntry(entry as dynamic) as dynamic
    if type(entry) = "roAssociativeArray" then
        id = AsText(entry.id)
        if id = "" then return invalid
        title = AsText(entry.title)
        if title = "" then title = AsText(entry.name)
        return { id: id, title: title, kind: AsText(entry.Lookup("type")) }
    end if
    id = AsText(entry)
    if id = "" then return invalid
    return { id: id, title: "", kind: "" }
end function

function AsText(v as dynamic) as string
    if type(v) = "Invalid" or type(v) = "<uninitialized>" then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    if GetInterface(v, "ifInt") <> invalid then return v.ToStr()
    return ""
end function

function IsInstalled(am as object, id as string) as boolean
    try
        return am.IsAppInstalled(id, "")
    catch e
        return false
    end try
end function

function IsTvInput(id as string) as boolean
    return Left(id, 8) = "tvinput."
end function

' "Pluto TV - Free Movies/Shows" becomes "Pluto TV" ...
function ShortTitle(title as string) as string
    t = title
    for each cut in [" - ", " – ", ": "]
        p = Instr(1, t, cut)
        if p > 1 then t = Left(t, p - 1)
    end for
    return t.Trim()
end function

' ... and "Free Movies/Shows" is what's on.
function Tagline(title as string, fallback as string) as string
    for each cut in [" - ", " – ", ": "]
        p = Instr(1, title, cut)
        if p > 0 then
            rest = Mid(title, p + Len(cut)).Trim()
            if rest <> "" then return rest
        end if
    end for
    return fallback
end function

' A call sign for an app b0r3d TV doesn't know: up to six letters and digits of its first word.
function MakeSign(name as string) as string
    words = name.Split(" ")
    word = ""
    if words.Count() > 0 then word = UCase(words[0])
    sign = ""
    for i = 1 to Len(word)
        c = Mid(word, i, 1)
        if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") then sign = sign + c
        if Len(sign) = 6 then exit for
    end for
    if sign = "" then sign = "APP"
    return sign
end function

function TwoDigits(n as integer) as string
    if n < 10 then return "0" + n.ToStr()
    return n.ToStr()
end function

' Apps b0r3d TV knows by number, with the name and call sign the guide shows. Kind "saver" is
' a screensaver app, never a channel.
function KnownApps() as object
    return [
        { id: "837", name: "YouTube", sign: "YTUBE", kind: "app" },
        { id: "74519", name: "Pluto TV", sign: "PLUTO", kind: "app" },
        { id: "41468", name: "Tubi", sign: "TUBI", kind: "app" },
        { id: "151908", name: "The Roku Channel", sign: "ROKU", kind: "app" },
        { id: "23353", name: "PBS", sign: "PBS", kind: "app" },
        { id: "2213", name: "Roku Media Player", sign: "MEDIA", kind: "app" },
        { id: "298229", name: "Frndly TV", sign: "FRNDLY", kind: "app" },
        { id: "606242", name: "Kids & Family", sign: "KIDS", kind: "app" },
        { id: "244655", name: "NASA", sign: "NASA", kind: "app" },
        { id: "12", name: "Netflix", sign: "NFLX", kind: "app" },
        { id: "13", name: "Prime Video", sign: "PRIME", kind: "app" },
        { id: "2285", name: "Hulu", sign: "HULU", kind: "app" },
        { id: "291097", name: "Disney+", sign: "DISNEY", kind: "app" },
        { id: "61322", name: "HBO Max", sign: "HBO", kind: "app" },
        { id: "31440", name: "Paramount+", sign: "PARA", kind: "app" },
        { id: "593099", name: "Peacock", sign: "PCOCK", kind: "app" },
        { id: "551012", name: "Apple TV", sign: "APPLE", kind: "app" },
        { id: "195316", name: "YouTube TV", sign: "YTTV", kind: "app" },
        { id: "46041", name: "Sling TV", sign: "SLING", kind: "app" },
        { id: "196460", name: "Philo", sign: "PHILO", kind: "app" },
        { id: "43465", name: "Fubo", sign: "FUBO", kind: "app" },
        { id: "140474", name: "DIRECTV", sign: "DTV", kind: "app" },
        { id: "22297", name: "Spotify", sign: "SPTFY", kind: "app" },
        { id: "19977", name: "Spotify", sign: "SPTFY", kind: "app" },
        { id: "28", name: "Pandora", sign: "PANDRA", kind: "app" },
        { id: "20197", name: "iHeart", sign: "IHEART", kind: "app" },
        { id: "14362", name: "Amazon Music", sign: "AMZM", kind: "app" },
        { id: "38345", name: "SiriusXM", sign: "SXM", kind: "app" },
        { id: "637193", name: "Apple Music", sign: "APLM", kind: "app" },
        { id: "13535", name: "Plex", sign: "PLEX", kind: "app" },
        { id: "592369", name: "Jellyfin", sign: "JELLY", kind: "app" },
        { id: "44191", name: "Emby", sign: "EMBY", kind: "app" },
        { id: "2595", name: "Crunchyroll", sign: "CRUNCH", kind: "app" },
        { id: "13842", name: "Fandango at Home", sign: "FANDGO", kind: "app" },
        { id: "65067", name: "STARZ", sign: "STARZ", kind: "app" },
        { id: "143088", name: "BritBox", sign: "BRITBX", kind: "app" },
        { id: "14295", name: "Acorn TV", sign: "ACORN", kind: "app" },
        { id: "593290", name: "discovery+", sign: "DSCVR", kind: "app" },
        { id: "34376", name: "ESPN", sign: "ESPN", kind: "app" },
        { id: "95307", name: "FOX Sports", sign: "FOXSP", kind: "app" },
        { id: "44856", name: "NFL", sign: "NFL", kind: "app" },
        { id: "73249", name: "NBA", sign: "NBA", kind: "app" },
        { id: "96065", name: "Xumo Play", sign: "XUMO", kind: "app" },
        { id: "2016", name: "Crackle", sign: "CRACKL", kind: "app" },
        { id: "122409", name: "Kanopy", sign: "KANOPY", kind: "app" },
        { id: "196549", name: "hoopla", sign: "HOOPLA", kind: "app" },
        { id: "23333", name: "PBS KIDS", sign: "PBSKID", kind: "app" },
        { id: "172665", name: "Haystack News", sign: "HAYSTK", kind: "app" },
        { id: "27536", name: "CBS News", sign: "CBSN", kind: "app" },
        { id: "9581", name: "NBC News", sign: "NBCN", kind: "app" },
        { id: "54065", name: "ABC News Live", sign: "ABCN", kind: "app" },
        { id: "97955", name: "Local Now", sign: "LOCAL", kind: "app" },
        { id: "273862", name: "The Weather Channel", sign: "WTHR", kind: "app" },
        { id: "53696", name: "Shout! TV", sign: "SHOUT", kind: "app" },
        { id: "552828", name: "ViX", sign: "VIX", kind: "app" },
        { id: "123095", name: "Aquatic Life", sign: "AQUA", kind: "saver" },
        { id: "271214", name: "Psychedelic Screensaver", sign: "PSYCH", kind: "saver" },
        { id: "773622", name: "Backdrops", sign: "BKDROP", kind: "saver" }
    ]
end function
