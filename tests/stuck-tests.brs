' The game-rule tests for Stuck Pixels. The BrightScript simulator runs them on a PC, and
' GitHub runs them on every push (tools/test-games.sh). Each test plays the rules in
' app/source/stuck.brs and games.brs move by move and checks what happened. The last line
' says how many passed.

sub Main()
    t = { passed: 0, failed: 0, fails: [] }
    tests = [
        { name: "every piece has 3 or 5 pixels and turns round to where it started", fn: TestPieceSet },
        { name: "no two pieces are the same shape", fn: TestPiecesDiffer },
        { name: "pieces come in at the top, in the middle", fn: TestSpawn },
        { name: "each bag holds every piece, the small ones twice", fn: TestBag },
        { name: "the same seed deals the same pieces", fn: TestSeed },
        { name: "left and right stop at the walls", fn: TestWalls },
        { name: "holding a direction slides after 170 ms, then every 50 ms", fn: TestHoldToSlide },
        { name: "a held key pressed again (a repeating remote) doesn't restart the slide", fn: TestRepeatedPress },
        { name: "down drops a row now and one every 45 ms while held, a point a row", fn: TestSoftDrop },
        { name: "up drops it all the way, 2 points a row, and sets it", fn: TestHardDrop },
        { name: "ghost row shows where up will set the falling piece", fn: TestGhost },
        { name: "a row a second at level 0, 80 ms faster a level, a tenth of a second at most", fn: TestGravity },
        { name: "a piece on the ground sets after half a second", fn: TestLockDelay },
        { name: "moving on the ground buys time, 15 times at most", fn: TestLockResets },
        { name: "falling to a lower row gives the 15 moves back", fn: TestLockResetsBack },
        { name: "a full row clears and the rows above come down", fn: TestLineClear },
        { name: "lines score 100, 300, 500, 800 and 1200 times the level plus one", fn: TestClearPoints },
        { name: "a full row with a stuck pixel pops it and stays, then clears when filled again", fn: TestStuckPixel },
        { name: "two rows at once: one clears, the one with a stuck pixel pops", fn: TestStuckWithClear },
        { name: "a popped pixel's hole comes down with the rows, and the sparks with it", fn: TestPopBelowClear },
        { name: "a stuck pixel stays itself as the piece turns", fn: TestStuckTurns },
        { name: "stuck pixels come 10 times in 100 at level 0, never more than 20", fn: TestStuckChance },
        { name: "Cleanup starts over rows of static, never full and never empty", fn: TestStatic },
        { name: "static clears like any other pixel", fn: TestStaticClears },
        { name: "Marathon goes up a level every 10 lines", fn: TestMarathon },
        { name: "Sprint 40 ends at 40 lines and times only the playing", fn: TestSprint },
        { name: "Cleanup ends at 25 lines with a bonus", fn: TestCleanup },
        { name: "hold puts a piece aside once a piece, then swaps", fn: TestHold },
        { name: "the run ends when a piece can't come in", fn: TestTopOut },
        { name: "a piece set partly above the well ends the run", fn: TestLockAbove },
        { name: "turning against a wall steps away from it", fn: TestKick },
        { name: "a left turn is three right turns", fn: TestTurnLeft },
        { name: "high scores keep the best 10 in order, the older first on a tie", fn: TestScoreTable },
        { name: "broken high-score tables are cleaned up", fn: TestScoreClean },
        { name: "initials are three letters or digits", fn: TestInitials },
        { name: "numbers and times are written the TV's way", fn: TestWords },
        { name: "the demo plays on its own and starts over", fn: TestDemo }
    ]
    for each test in tests
        t.fails = []
        try
            fn = test.fn
            fn(t)
        catch e
            t.fails.Push("crashed: " + e.message)
        end try
        if t.fails.Count() = 0 then
            t.passed = t.passed + 1
            print "ok - "; test.name
        else
            t.failed = t.failed + 1
            print "FAILED - "; test.name
            for each why in t.fails
                print "    "; why
            end for
        end if
    end for
    print "game-rule tests: "; t.passed.ToStr(); " passed, "; t.failed.ToStr(); " failed"
end sub

' --- Helpers ---

sub Check(t as object, ok as boolean, what as string)
    if not ok then t.fails.Push(what)
end sub

sub Same(t as object, got as dynamic, want as dynamic, what as string)
    if got <> want then t.fails.Push(what + ": got " + AnyText(got) + ", wanted " + AnyText(want))
end sub

function AnyText(v as dynamic) as string
    if type(v) = "Invalid" or type(v) = "roInvalid" then return "invalid"
    if GetInterface(v, "ifString") <> invalid then return v
    if GetInterface(v, "ifToStr") <> invalid then return v.ToStr()
    return type(v)
end function

' A run on an empty well, Marathon from level, with nothing in play yet.
function EmptyGame(level as integer) as object
    g = SpNew("marathon", level, 0, 4242)
    ClearBoard(g)
    return g
end function

sub ClearBoard(g as object)
    for r = 0 to g.rows - 1
        for c = 0 to g.cols - 1
            g.board[r][c] = 0
        end for
    end for
end sub

function PieceNumber(g as object, name as string) as integer
    for i = 0 to g.shapes.Count() - 1
        if g.shapes[i].name = name then return i
    end for
    return -1
end function

' Puts a piece in play at its box's row and column, turned rot times to the right.
sub PutPiece(g as object, name as string, rot as integer, row as integer, col as integer, stuck as integer)
    g.cur = { p: PieceNumber(g, name), stuck: stuck, rot: rot, row: row, col: col }
    g.lowest = row
    g.lockT = 0
    g.lockMoves = 0
    g.fallT = 0
    g.holdUsed = false
end sub

' Fills a row from a pattern: "#" a pixel, "*" a stuck pixel, "s" static, anything else empty.
sub SetRow(g as object, r as integer, pattern as string)
    for c = 0 to g.cols - 1
        ch = Mid(pattern, c + 1, 1)
        v = 0
        if ch = "#" then v = 1
        if ch = "*" then v = 2
        if ch = "s" then v = 3
        g.board[r][c] = v
    end for
end sub

function RowText(g as object, r as integer) as string
    out = ""
    for each v in g.board[r]
        if v = 0 then
            out = out + "."
        else if v = 1 then
            out = out + "#"
        else if v = 2 then
            out = out + "*"
        else
            out = out + "s"
        end if
    end for
    return out
end function

' A piece's cells as one text, moved so its top left is at 0, 0, to compare shapes.
function ShapeKey(cells as object) as string
    minR = 99
    minC = 99
    for each cell in cells
        if cell[0] < minR then minR = cell[0]
        if cell[1] < minC then minC = cell[1]
    end for
    keys = []
    for each cell in cells
        keys.Push(((cell[0] - minR) * 10 + (cell[1] - minC)).ToStr())
    end for
    keys.Sort()
    out = ""
    for each k in keys
        out = out + k + ","
    end for
    return out
end function

' --- Tests ---

sub TestPieceSet(t as object)
    g = EmptyGame(0)
    sawThree = false
    sawFive = false
    Check(t, g.shapes.Count() >= 8, "there are at least 8 pieces")
    for each shape in g.shapes
        n = shape.cells[0].Count()
        Check(t, n = 3 or n = 5, shape.name + " has 3 or 5 pixels, not " + n.ToStr())
        if n = 3 then sawThree = true
        if n = 5 then sawFive = true
        for rot = 0 to 3
            Same(t, shape.cells[rot].Count(), n, shape.name + " turn " + rot.ToStr() + " keeps its pixels")
            for each cell in shape.cells[rot]
                Check(t, cell[0] >= 0 and cell[0] < shape.size and cell[1] >= 0 and cell[1] < shape.size, shape.name + " stays in its box")
            end for
        end for
        ' a fourth quarter turn is where it started
        back = []
        for each cell in shape.cells[3]
            back.Push([cell[1], shape.size - 1 - cell[0]])
        end for
        Same(t, ShapeKey(back), ShapeKey(shape.cells[0]), shape.name + " turns round to where it started")
        for i = 0 to n - 1
            Check(t, back[i][0] = shape.cells[0][i][0] and back[i][1] = shape.cells[0][i][1], shape.name + " keeps its pixels in order")
        end for
    end for
    Check(t, sawThree, "some pieces have 3 pixels")
    Check(t, sawFive, "some pieces have 5 pixels")
end sub

sub TestPiecesDiffer(t as object)
    g = EmptyGame(0)
    seen = {}
    for each shape in g.shapes
        for rot = 0 to 3
            key = ShapeKey(shape.cells[rot])
            if seen.DoesExist(key) then
                Check(t, seen[key] = shape.name, shape.name + " is the same shape as " + seen[key])
            else
                seen[key] = shape.name
            end if
        end for
    end for
end sub

sub TestSpawn(t as object)
    g = EmptyGame(0)
    for i = 0 to g.shapes.Count() - 1
        ClearBoard(g)
        g.state = "play"
        SpPlace(g, { p: i, stuck: -1 })
        shape = g.shapes[i]
        Same(t, g.state, "play", shape.name + " comes in")
        Same(t, g.cur.col, (g.cols - shape.size) \ 2, shape.name + "'s column")
        top = 99
        for each cell in SpCells(g)
            if cell[0] < top then top = cell[0]
        end for
        Same(t, top, 0, shape.name + "'s top row")
    end for
end sub

sub TestBag(t as object)
    g = EmptyGame(0)
    g.bag = []
    counts = []
    total = 0
    for each shape in g.shapes
        counts.Push(0)
        total = total + shape.copies
    end for
    for n = 1 to total * 3
        piece = SpDraw(g)
        counts[piece.p] = counts[piece.p] + 1
    end for
    for i = 0 to g.shapes.Count() - 1
        Same(t, counts[i], g.shapes[i].copies * 3, g.shapes[i].name + " in three bags")
    end for
    Same(t, g.shapes[PieceNumber(g, "bar3")].copies, 2, "the 3-pixel bar comes twice a bag")
    Same(t, g.shapes[PieceNumber(g, "elbow3")].copies, 2, "the 3-pixel elbow comes twice a bag")
end sub

sub TestSeed(t as object)
    a = SpNew("marathon", 0, 0, 777)
    b = SpNew("marathon", 0, 0, 777)
    c = SpNew("marathon", 0, 0, 778)
    sameAB = true
    sameAC = true
    for n = 1 to 100
        pa = SpDraw(a)
        pb = SpDraw(b)
        pc = SpDraw(c)
        if pa.p <> pb.p or pa.stuck <> pb.stuck then sameAB = false
        if pa.p <> pc.p or pa.stuck <> pc.stuck then sameAC = false
    end for
    Check(t, sameAB, "the same seed deals the same 100 pieces")
    Check(t, not sameAC, "another seed deals other pieces")
end sub

sub TestWalls(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    for n = 1 to 6
        SpPress(g, "left")
        SpRelease(g, "left")
    end for
    Same(t, g.cur.col, 0, "left stops at the wall")
    for n = 1 to 15
        SpPress(g, "right")
        SpRelease(g, "right")
    end for
    Same(t, g.cur.col, 9, "right stops at the wall")
    SetRow(g, 0, "#...........")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    for n = 1 to 6
        SpPress(g, "left")
        SpRelease(g, "left")
    end for
    Same(t, g.cur.col, 1, "left stops at a pixel")
end sub

sub TestHoldToSlide(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 9, -1)
    SpPress(g, "left")
    Same(t, g.cur.col, 8, "one step at once")
    SpTick(g, 169)
    Same(t, g.cur.col, 8, "nothing more before 170 ms")
    SpTick(g, 1)
    Same(t, g.cur.col, 7, "the slide starts at 170 ms")
    SpTick(g, 49)
    Same(t, g.cur.col, 7, "nothing more before another 50 ms")
    SpTick(g, 1)
    Same(t, g.cur.col, 6, "a step every 50 ms")
    SpTick(g, 100)
    Same(t, g.cur.col, 4, "two more in 100 ms")
    SpRelease(g, "left")
    SpTick(g, 300)
    Same(t, g.cur.col, 4, "letting go stops it")
    Same(t, g.cur.row, -1, "it didn't fall in under a second")
    ' one long step of time (the rules take any length) still moves the right number of times
    PutPiece(g, "bar3", 0, -1, 9, -1)
    SpPress(g, "left")
    SpTick(g, 270)
    Same(t, g.cur.col, 5, "170 ms and two 50s in one 270 ms frame")
    SpRelease(g, "left")
end sub

sub TestRepeatedPress(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 9, -1)
    SpPress(g, "left")
    SpTick(g, 100)
    SpPress(g, "left")
    Same(t, g.cur.col, 8, "the second press of a held key doesn't move it")
    SpTick(g, 70)
    Same(t, g.cur.col, 7, "the slide still starts 170 ms after the first press")
    SpRelease(g, "left")
    SpPress(g, "left")
    Same(t, g.cur.col, 6, "after letting go, a press moves again")
    SpRelease(g, "left")
    g.score = 0
    SpPress(g, "down")
    SpTick(g, 30)
    SpPress(g, "down")
    Same(t, g.score, 1, "Down pressed again while held doesn't drop an extra row")
    SpTick(g, 15)
    Same(t, g.score, 2, "and the 45 ms beat goes on")
    SpRelease(g, "down")
end sub

sub TestSoftDrop(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    g.score = 0
    SpPress(g, "down")
    Same(t, g.cur.row, 0, "a row at once")
    Same(t, g.score, 1, "a point a row")
    SpTick(g, 44)
    Same(t, g.cur.row, 0, "nothing more before 45 ms")
    SpTick(g, 1)
    Same(t, g.cur.row, 1, "a row every 45 ms")
    SpTick(g, 90)
    Same(t, g.cur.row, 3, "two more in 90 ms")
    Same(t, g.score, 4, "four points for four rows")
    SpRelease(g, "down")
    SpTick(g, 300)
    Same(t, g.cur.row, 3, "letting go stops it")
end sub

sub TestHardDrop(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    g.score = 0
    SpPress(g, "drop")
    Same(t, RowText(g, 17), "....###.....", "it lands on the floor")
    Same(t, g.score, 34, "17 rows down is 34 points")
    Same(t, g.pieces, 1, "it is set at once")
    Same(t, g.state, "play", "the next piece is in play")
    Check(t, g.cur.row <= 0, "the next piece is at the top")
end sub

sub TestGhost(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    Same(t, SpGhostRow(g), 16, "on an empty well the ghost rests at row 16")
    Same(t, g.cur.row, -1, "reading the ghost row leaves the falling piece put")
    SetRow(g, 14, ".....#......")
    Same(t, SpGhostRow(g), 12, "ghost stops right above a landed pixel")
    PutPiece(g, "bar3", 0, 12, 4, -1)
    Same(t, SpGhostRow(g), 12, "when already grounded, ghost matches current row")
    PutPiece(g, "bar3", 0, 2, 4, -1)
    g.score = 0
    SpPress(g, "drop")
    Same(t, RowText(g, 13), "....###.....", "hard drop lands at the ghost row")
    Same(t, g.score, 20, "10 rows dropped scores 20 points")
end sub

sub TestGravity(t as object)
    Same(t, SpDropMs(0), 1000, "level 0")
    Same(t, SpDropMs(1), 920, "level 1")
    Same(t, SpDropMs(5), 600, "level 5")
    Same(t, SpDropMs(9), 280, "level 9")
    Same(t, SpDropMs(11), 120, "level 11")
    Same(t, SpDropMs(12), 100, "level 12")
    Same(t, SpDropMs(20), 100, "level 20")
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpTick(g, 999)
    Same(t, g.cur.row, -1, "nothing before a second")
    SpTick(g, 1)
    Same(t, g.cur.row, 0, "a row after a second")
    g = EmptyGame(9)
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpTick(g, 560)
    Same(t, g.cur.row, 1, "two rows in 560 ms at level 9")
end sub

sub TestLockDelay(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, 16, 4, -1)
    Check(t, SpGrounded(g), "on the floor")
    SpTick(g, 499)
    Same(t, g.pieces, 0, "not set before 500 ms")
    SpTick(g, 1)
    Same(t, g.pieces, 1, "set at 500 ms")
    Same(t, RowText(g, 17), "....###.....", "where it sat")
end sub

sub TestLockResets(t as object)
    g = EmptyGame(0)
    PutPiece(g, "bar3", 0, 16, 4, -1)
    for n = 1 to 15
        SpTick(g, 400)
        if n mod 2 = 1 then
            SpPress(g, "left")
            SpRelease(g, "left")
        else
            SpPress(g, "right")
            SpRelease(g, "right")
        end if
    end for
    Same(t, g.pieces, 0, "15 moves on the ground keep it from setting")
    SpTick(g, 400)
    SpPress(g, "left")
    SpRelease(g, "left")
    SpTick(g, 99)
    Same(t, g.pieces, 0, "not set 499 ms after the 15th move")
    SpTick(g, 1)
    Same(t, g.pieces, 1, "the 16th move buys no more time")
end sub

sub TestLockResetsBack(t as object)
    g = EmptyGame(0)
    ' a ledge: the piece sits on it, uses up its moves, then slides off and falls
    SetRow(g, 10, "#####.......")
    PutPiece(g, "bar3", 0, 8, 2, -1)
    for n = 1 to 15
        SpTick(g, 100)
        if n mod 2 = 1 then
            SpPress(g, "left")
            SpRelease(g, "left")
        else
            SpPress(g, "right")
            SpRelease(g, "right")
        end if
    end for
    Same(t, g.lockMoves, 15, "all 15 moves used on the ledge")
    Same(t, g.pieces, 0, "still not set")
    for n = 1 to 4
        SpPress(g, "right")
        SpRelease(g, "right")
    end for
    SpTick(g, 1000)
    Check(t, g.cur.row > 8, "it fell off the ledge")
    Same(t, g.lockMoves, 0, "a lower row gives the moves back")
end sub

sub TestLineClear(t as object)
    g = EmptyGame(0)
    SetRow(g, 16, "#...........")
    SetRow(g, 17, "####...#####")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    g.score = 0
    SpPress(g, "drop")
    Same(t, g.lines, 1, "one line")
    Same(t, RowText(g, 17), "#...........", "the row above came down")
    Same(t, RowText(g, 16), "............", "an empty row on top")
    Same(t, g.score, 2 * 17 + 100, "drop points and 100 for a line at level 0")
end sub

sub TestClearPoints(t as object)
    want = [0, 100, 300, 500, 800, 1200]
    for n = 1 to 5
        g = EmptyGame(3)
        for r = 18 - n to 17
            SetRow(g, r, ".###########")
        end for
        ' the 5-pixel bar standing up, in the first column
        PutPiece(g, "bar5", 1, 0, -2, -1)
        g.score = 0
        start = g.cur.row
        SpPress(g, "drop")
        Same(t, g.lines, n, n.ToStr() + " lines at once")
        dist = 13 - start
        Same(t, g.score, 2 * dist + want[n] * 4, n.ToStr() + " lines at level 3")
    end for
end sub

sub TestStuckPixel(t as object)
    g = EmptyGame(2)
    SetRow(g, 17, "#####*#####.")
    ' the 3-pixel bar standing up, dropped into the last column
    PutPiece(g, "bar3", 1, 0, 10, -1)
    g.score = 0
    SpPress(g, "drop")
    Same(t, g.lines, 0, "the row with the stuck pixel doesn't clear")
    Same(t, RowText(g, 17), "#####.######", "the stuck pixel popped out and left a hole")
    Same(t, g.fixed, 1, "one stuck pixel fixed")
    Same(t, g.score, 2 * 15 + 200 * 3, "200 times the level plus one for fixing it")
    Same(t, g.stuckNow, 0, "no stuck pixel left")
    ' fill the hole: now it clears
    PutPiece(g, "bar3", 1, 0, 4, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 1, "filled again, it clears")
    Same(t, RowText(g, 17), ".....#.....#", "the rows above came down")
end sub

sub TestStuckWithClear(t as object)
    g = EmptyGame(0)
    SetRow(g, 16, "###########.")
    SetRow(g, 17, "###*#######.")
    PutPiece(g, "bar3", 1, 0, 10, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 1, "one line cleared")
    Same(t, g.fixed, 1, "one stuck pixel fixed")
    Same(t, RowText(g, 17), "###.########", "the bottom row stayed with a hole")
    Same(t, RowText(g, 16), "...........#", "the top pixel of the bar came down a row")
end sub

sub TestPopBelowClear(t as object)
    g = EmptyGame(0)
    SetRow(g, 16, "#####*#####.")
    SetRow(g, 17, "###########.")
    PutPiece(g, "bar3", 1, 0, 10, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 1, "the bottom row cleared")
    Same(t, RowText(g, 17), "#####.######", "the row with the hole came down to the bottom")
    where = ""
    for each e in g.events
        if e.kind = "fix" then where = e.data[0][0].ToStr() + "," + e.data[0][1].ToStr()
    end for
    Same(t, where, "17,5", "the sparks go where the hole is now")
end sub

sub TestStuckTurns(t as object)
    g = EmptyGame(0)
    ' the hook's first pixel stuck; after any turns, that pixel lands stuck
    for turns = 0 to 3
        ClearBoard(g)
        g.state = "play"
        PutPiece(g, "hook", 0, 2, 4, 0)
        before = SpCells(g)[0]
        for n = 1 to turns
            SpTurn(g, 1)
        end for
        cells = SpCells(g)
        stuckCell = cells[0]
        SpLock(g)
        Same(t, g.board[stuckCell[0]][stuckCell[1]], 2, "after " + turns.ToStr() + " turns the stuck pixel is still stuck")
        Same(t, SpCountStuck(g), 1, "only one stuck pixel")
        Check(t, before.Count() = 2, "cells are row and column")
    end for
end sub

sub TestStuckChance(t as object)
    g = EmptyGame(0)
    stuck = 0
    for n = 1 to 3000
        piece = SpDraw(g)
        if piece.stuck >= 0 then
            stuck = stuck + 1
            Check(t, piece.stuck < g.shapes[piece.p].cells[0].Count(), "the stuck pixel is one of the piece's")
        end if
    end for
    Check(t, stuck > 210 and stuck < 390, "about 10 in 100 at level 0, got " + stuck.ToStr() + " in 3000")
    g.level = 15
    stuck = 0
    for n = 1 to 3000
        if SpDraw(g).stuck >= 0 then stuck = stuck + 1
    end for
    Check(t, stuck > 480 and stuck < 720, "20 in 100 at most, got " + stuck.ToStr() + " in 3000 at level 15")
end sub

sub TestStatic(t as object)
    for each count in SpStaticChoices()
        g = SpNew("cleanup", 0, count, 99 + count)
        Same(t, g.staticRows, count, "rows of static asked for")
        for r = 0 to g.rows - 1
            n = 0
            for each v in g.board[r]
                if v = 3 then n = n + 1
                Check(t, v = 0 or v = 3, "only static at the start")
            end for
            if r >= g.rows - count then
                Check(t, n > 0 and n < g.cols, "row " + r.ToStr() + " is neither full nor empty")
            else
                Same(t, n, 0, "row " + r.ToStr() + " above the static is empty")
            end if
        end for
    end for
    g = SpNew("marathon", 0, 6, 5)
    Same(t, CountStatic(g), 0, "only Cleanup starts with static")
end sub

function CountStatic(g as object) as integer
    n = 0
    for each row in g.board
        for each v in row
            if v = 3 then n = n + 1
        end for
    end for
    return n
end function

sub TestStaticClears(t as object)
    g = SpNew("cleanup", 0, 0, 3)
    ClearBoard(g)
    SetRow(g, 17, "ssss...sssss")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 1, "a row of static and pixels clears")
    Same(t, RowText(g, 17), "............", "nothing left")
end sub

sub TestMarathon(t as object)
    g = EmptyGame(3)
    g.lines = 9
    SetRow(g, 17, "####...#####")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 10, "ten lines")
    Same(t, g.level, 4, "level 4 after 10 lines from level 3")
    Same(t, g.state, "play", "Marathon goes on")
    g.lines = 39
    SetRow(g, 17, "####...#####")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.level, 7, "level 7 at 40 lines from level 3")
    Same(t, g.state, "play", "Marathon has no finish line")
end sub

sub TestSprint(t as object)
    g = SpNew("sprint", 5, 0, 8)
    ClearBoard(g)
    SpTick(g, 100)
    Same(t, g.elapsed, 100, "time runs while playing")
    g.lines = 38
    SetRow(g, 16, "####...#####")
    SetRow(g, 17, "####...#####")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 39, "39 lines")
    Same(t, g.level, 5, "Sprint stays at its start level")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.lines, 40, "40 lines")
    Same(t, g.state, "done", "Sprint ends at 40 lines")
    took = g.elapsed
    SpTick(g, 5000)
    Same(t, g.elapsed, took, "the clock stops at the finish")
end sub

sub TestCleanup(t as object)
    g = SpNew("cleanup", 2, 4, 9)
    ClearBoard(g)
    g.lines = 24
    g.score = 0
    SetRow(g, 17, "####...#####")
    PutPiece(g, "bar3", 0, -1, 4, -1)
    SpPress(g, "drop")
    Same(t, g.state, "done", "Cleanup ends at 25 lines")
    Same(t, g.level, 2, "Cleanup stays at its start level")
    Same(t, g.score, 2 * 17 + 100 * 3 + 1000 * 3, "a line plus the finishing bonus at level 2")
end sub

sub TestHold(t as object)
    g = EmptyGame(0)
    first = g.cur.p
    coming = g.upcoming.p
    g.cur.stuck = 1
    SpPress(g, "hold")
    Check(t, g.held <> invalid, "the piece is put aside")
    Same(t, g.held.p, first, "the piece put aside")
    Same(t, g.held.stuck, 1, "its stuck pixel goes with it")
    Same(t, g.cur.p, coming, "the next piece comes in")
    second = g.cur.p
    SpPress(g, "hold")
    Same(t, g.cur.p, second, "only once a piece")
    SpPress(g, "drop")
    third = g.cur.p
    SpPress(g, "hold")
    Same(t, g.cur.p, first, "after a piece is set, hold swaps")
    Same(t, g.cur.stuck, 1, "the stuck pixel comes back with it")
    Same(t, g.held.p, third, "and the one in play goes aside")
    Same(t, g.cur.rot, 0, "it comes back unturned")
end sub

sub TestTopOut(t as object)
    g = EmptyGame(0)
    SetRow(g, 0, ".....#......")
    SpPlace(g, { p: PieceNumber(g, "bar3"), stuck: -1 })
    Same(t, g.state, "over", "no room to come in")
    found = false
    for each e in g.events
        if e.kind = "over" then found = true
    end for
    Check(t, found, "the screen hears it's over")
    SpPress(g, "left")
    SpTick(g, 5000)
    Same(t, g.state, "over", "nothing moves after the end")
end sub

sub TestLockAbove(t as object)
    g = EmptyGame(0)
    SetRow(g, 1, ".....#......")
    ' the 3-pixel bar standing up with its top two pixels above the well
    PutPiece(g, "bar3", 1, -2, 4, -1)
    Check(t, SpGrounded(g), "it sits on the pixel")
    SpTick(g, 500)
    Same(t, g.state, "over", "set above the well is the end")
end sub

sub TestKick(t as object)
    g = EmptyGame(0)
    ' standing up against the left wall: lying down needs a step to the right
    PutPiece(g, "bar3", 1, 5, -1, -1)
    Check(t, SpTurn(g, 1), "the turn works")
    Same(t, g.cur.rot, 2, "it turned")
    Same(t, g.cur.col, 0, "a step away from the wall")
    PutPiece(g, "bar3", 1, 5, 10, -1)
    Check(t, SpTurn(g, 1), "the turn works at the right wall")
    Same(t, g.cur.col, 9, "a step away from the right wall")
    ' boxed in: no turn
    ClearBoard(g)
    SetRow(g, 5, "##.#########")
    SetRow(g, 6, "##.#########")
    SetRow(g, 7, "##.#########")
    PutPiece(g, "bar3", 1, 5, 1, -1)
    Check(t, SpFits(g, g.cur.p, 1, 5, 1), "standing in the slot")
    Check(t, not SpTurn(g, 1), "no room to turn")
    Same(t, g.cur.rot, 1, "still standing")
end sub

sub TestTurnLeft(t as object)
    g = EmptyGame(0)
    for i = 0 to g.shapes.Count() - 1
        PutPiece(g, g.shapes[i].name, 0, 6, 4, -1)
        SpTurn(g, 3)
        once = CellsText(SpCells(g))
        PutPiece(g, g.shapes[i].name, 0, 6, 4, -1)
        SpTurn(g, 1)
        SpTurn(g, 1)
        SpTurn(g, 1)
        Same(t, CellsText(SpCells(g)), once, g.shapes[i].name + " turned left once or right three times")
    end for
end sub

function CellsText(cells as object) as string
    out = ""
    for each cell in cells
        out = out + cell[0].ToStr() + "," + cell[1].ToStr() + ";"
    end for
    return out
end function

sub TestScoreTable(t as object)
    list = []
    Same(t, ScoreRank(list, 50, false), 0, "an empty table takes anything first")
    for each v in [500, 300, 900, 100, 700]
        ScoreInsert(list, { i: "AAA", v: v }, false)
    end for
    order = ""
    for each e in list
        order = order + e.v.ToStr() + " "
    end for
    Same(t, order, "900 700 500 300 100 ", "best first")
    place = ScoreInsert(list, { i: "NEW", v: 500 }, false)
    Same(t, place, 3, "a tie goes below the older one")
    Same(t, list[2].i, "AAA", "the older 500 stays ahead")
    for n = 1 to 10
        ScoreInsert(list, { i: "MOR", v: 1000 + n }, false)
    end for
    Same(t, list.Count(), 10, "never more than 10")
    Same(t, ScoreRank(list, 5, false), -1, "a low score misses a full table")
    Same(t, list[0].v, 1010, "the best is first")
    times = []
    for each v in [90000, 60000, 75000]
        ScoreInsert(times, { i: "ZZZ", v: v }, true)
    end for
    Same(t, times[0].v, 60000, "the fastest time is first")
    Same(t, ScoreInsert(times, { i: "TOP", v: 59999 }, true), 0, "a faster time takes the top")
end sub

sub TestScoreClean(t as object)
    raw = ParseJson("[{""i"":""ABC"",""v"":10},{""i"":5,""v"":3},""junk"",{""i"":""DEF""},{""i"":""GHI"",""v"":2}]")
    list = CleanScoreTable(raw)
    Same(t, list.Count(), 2, "only the good entries are kept")
    Same(t, list[1].i, "GHI", "in their order")
    Same(t, CleanScoreTable(invalid).Count(), 0, "nothing saved is an empty table")
    Same(t, CleanScoreTable(ParseJson("{""a"":1}")).Count(), 0, "not a list is an empty table")
end sub

sub TestInitials(t as object)
    Same(t, NextLetter("A", 1), "B", "A then B")
    Same(t, NextLetter("A", -1), "9", "before A comes 9")
    Same(t, NextLetter("9", 1), "A", "after 9 comes A")
    Same(t, NextLetter("Z", 1), "0", "after Z comes 0")
    Same(t, CleanInitials("ab"), "ABA", "lower case and missing letters")
    Same(t, CleanInitials("x!z"), "XAZ", "a sign becomes A")
    Same(t, CleanInitials("KITTY"), "KIT", "three at most")
end sub

sub TestWords(t as object)
    Same(t, GroupDigits(0), "0", "0")
    Same(t, GroupDigits(999), "999", "999")
    Same(t, GroupDigits(1000), "1,000", "1,000")
    Same(t, GroupDigits(1234567), "1,234,567", "a million")
    Same(t, TimeWord(0), "0:00.0", "no time")
    Same(t, TimeWord(83456), "1:23.4", "a minute and a bit")
    Same(t, TimeWord(605000), "10:05.0", "ten minutes")
    Same(t, PlaceWord(0), "1st", "first")
    Same(t, PlaceWord(1), "2nd", "second")
    Same(t, PlaceWord(2), "3rd", "third")
    Same(t, PlaceWord(3), "4th", "fourth")
    Same(t, PlaceWord(10), "11th", "eleventh")
    Same(t, PlaceWord(11), "12th", "twelfth")
    Same(t, PlaceWord(20), "21st", "twenty-first")
end sub

sub TestDemo(t as object)
    d = SpDemoNew(31337)
    bestLines = 0
    restarts = 0
    lastSeed = d.seed
    for n = 1 to 4000
        SpDemoStep(d)
        if d.g.lines > bestLines then bestLines = d.g.lines
        if d.seed <> lastSeed then
            restarts = restarts + 1
            lastSeed = d.seed
        end if
    end for
    Check(t, bestLines >= 5, "the demo clears lines, best " + bestLines.ToStr())
    Check(t, d.g.events.Count() <= 12, "the demo doesn't pile up events")
    Check(t, d.g.state = "play" or d.rest <= 9, "the demo starts over after the end")
    print "    (demo: best "; bestLines.ToStr(); " lines, "; restarts.ToStr(); " restarts in 4000 steps)"
end sub
