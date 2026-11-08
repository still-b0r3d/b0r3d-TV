' The game-rule tests for Test Pattern. The BrightScript simulator runs them on a PC, and
' GitHub runs them on every push (tools/test-games.sh). Each test plays the rules in
' app/source/testpattern.brs (with games.brs) and checks what happened. The last line says how
' many passed.

sub Main()
    t = { passed: 0, failed: 0, fails: [] }
    tests = [
        { name: "the six campaign walls are two bricks for every one, with the same capsules", fn: TestWalls },
        { name: "every brick takes its column's colour bar, eight bars across", fn: TestBars },
        { name: "easy, normal and hard: lives, paddle width, ball speed and points, rounded", fn: TestDifficulty },
        { name: "the ball waits on the paddle until OK, then goes up", fn: TestServe },
        { name: "the paddle starts slow, speeds up while held, and stops at the sides", fn: TestPaddle },
        { name: "a held direction pressed again doesn't slow the paddle down", fn: TestPaddleRepeat },
        { name: "a ball on the paddle rides along with it", fn: TestRide },
        { name: "the ball bounces off the sides and the top", fn: TestWallBounce },
        { name: "the paddle sends the ball back up, up to 60 degrees off by where it hits", fn: TestPaddleBounce },
        { name: "a brick hit turns the ball back and pays its points times the difficulty's", fn: TestBrick },
        { name: "a ball rising under the gap between two bricks turns back down and takes one", fn: TestBrickSeam },
        { name: "a ball coming at a brick's side turns back the way it came", fn: TestBrickSide },
        { name: "a bomb takes the eight bricks around it a moment later, and sets off bombs", fn: TestBomb },
        { name: "a capsule brick drops its capsule; the paddle catches it, or it falls past and is gone", fn: TestCapsule },
        { name: "wide makes the paddle half again as wide, until a life is lost", fn: TestWide },
        { name: "sticky holds the ball for 12 s where it lands; OK lets it go at that spot's angle", fn: TestSticky },
        { name: "sticky holds one ball without losing the others", fn: TestStickyMany },
        { name: "slow makes the ball 0.6 times as fast for 8 s, then wears off", fn: TestSlow },
        { name: "more balls: two more each time, six at most", fn: TestMulti },
        { name: "a life capsule adds a life, and a mystery is one of the others", fn: TestLifeAndMystery },
        { name: "losing every ball costs a life, clears the capsules and serves again; no lives is the end", fn: TestLives },
        { name: "a cleared wall puts everything away and waits for OK; the next starts afresh", fn: TestClear },
        { name: "Endless walls get faster up to twice, grow, and have capsules and bombs", fn: TestEndless },
        { name: "the same seed builds the same walls", fn: TestSeed },
        { name: "even the fastest ball can't pass through a brick, from any start", fn: TestNoTunnel },
        { name: "the demo plays on its own and starts over, with no ball in a brick or out of the field", fn: TestDemo }
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

' Close enough, for positions and speeds.
sub Near(t as object, got as float, want as float, within as float, what as string)
    if Abs(got - want) > within then t.fails.Push(what + ": got " + Str(got).Trim() + ", wanted " + Str(want).Trim() + " (+/- " + Str(within).Trim() + ")")
end sub

function AnyText(v as dynamic) as string
    if type(v) = "Invalid" or type(v) = "roInvalid" then return "invalid"
    if GetInterface(v, "ifString") <> invalid then return v
    if GetInterface(v, "ifToStr") <> invalid then return v.ToStr()
    return type(v)
end function

function CountChars(text as string, chars as string) as integer
    n = 0
    for i = 1 to Len(text)
        if Instr(1, chars, Mid(text, i, 1)) > 0 then n = n + 1
    end for
    return n
end function

function JoinRows(rows as object) as string
    out = ""
    for each row in rows
        out = out + row
    end for
    return out
end function

' A run in play with a wall of the given rows, the served ball still resting on the paddle
' (so the run isn't short of balls), and no events yet.
function PlayGame(mode as string, difficulty as string, rows as object) as object
    g = TpNew(mode, difficulty, 99)
    TpBuildBricks(g, rows)
    g.state = "play"
    g.events.Clear()
    return g
end function

' A loose ball at x, y moving vx, vy.
function LooseBall(x as float, y as float, vx as float, vy as float) as object
    return { x: x, y: y, vx: vx, vy: vy, speed: Sqr(vx * vx + vy * vy), stuck: false, dx: 0.0 }
end function

function BrickAt(g as object, row as integer, col as integer) as dynamic
    return g.grid[row][col]
end function

function HasEvent(g as object, kind as string) as boolean
    for each e in g.events
        if e.kind = kind then return true
    end for
    return false
end function

function EmptyRows(n as integer) as object
    rows = []
    for i = 1 to n
        rows.Push("................")
    end for
    return rows
end function

' --- Tests ---

sub TestWalls(t as object)
    walls = TpCampaign()
    Same(t, walls.Count(), 6, "six campaign walls")
    for i = 0 to walls.Count() - 1
        narrow = JoinRows(walls[i].rows)
        wide = JoinRows(TpWideWall(walls[i].rows))
        for each row in TpWideWall(walls[i].rows)
            Same(t, Len(row), 16, "wall " + (i + 1).ToStr() + " is 16 bricks across")
        end for
        Same(t, CountChars(wide, "MWSZLP"), CountChars(narrow, "MWSZLP"), "wall " + (i + 1).ToStr() + " keeps its capsules")
        Same(t, CountChars(wide, "B"), 2 * CountChars(narrow, "B"), "wall " + (i + 1).ToStr() + "'s bombs are two wide")
        Same(t, CountChars(wide, "."), 2 * CountChars(narrow, "."), "wall " + (i + 1).ToStr() + "'s gaps are two wide")
    end for
    Same(t, TpWideWall(["333WS333"])[0], "333333W3S3333333", "a capsule brick is the capsule and a plain brick")
    Same(t, walls[0].speed, 1.0, "the first wall at the base speed")
    Same(t, walls[5].speed, 1.5, "the sixth half again as fast")
end sub

sub TestBars(t as object)
    g = TpNew("campaign", "normal", 1)
    TpBuildBricks(g, ["1111111111111111"])
    bars = ""
    for each k in g.bricks
        bars = bars + k.bar.ToStr()
    end for
    Same(t, bars, "0011223344556677", "16 bricks: each bar two bricks wide")
    TpBuildBricks(g, ["11111111111111111111"])
    last = 0
    ok = true
    for each k in g.bricks
        if k.bar < last or k.bar > 7 then ok = false
        last = k.bar
    end for
    Check(t, ok and g.bricks[0].bar = 0 and g.bricks[19].bar = 7, "20 bricks: the bars go 0 to 7 from left to right")
    w = g.brickW
    Near(t, g.bricks[19].x + w, g.rules.w - g.rules.margin, 0.01, "the wall reaches the right margin")
end sub

sub TestDifficulty(t as object)
    want = { easy: [5, 200, 238], normal: [3, 150, 280], hard: [2, 116, 336] }
    for each name in TpDifficulties()
        g = TpNew("campaign", name, 1)
        Same(t, g.lives, want[name][0], name + " lives")
        Near(t, g.paddle.w, want[name][1], 0.01, name + " paddle width")
        Near(t, TpSpeed(g), want[name][2], 0.01, name + " ball speed on the first wall")
    end for
    for each pair in [["easy", 5], ["normal", 10], ["hard", 15]]
        g = PlayGame("endless", pair[0], ["1...............", "...............1"])
        TpKill(g, BrickAt(g, 0, 0))
        Same(t, g.score, pair[1], pair[0] + ": a 10-point brick")
    end for
    ' half and one and a half times 25 round to the nearest point
    for each pair in [["easy", 13], ["normal", 25], ["hard", 38]]
        g = PlayGame("endless", pair[0], ["B...............", "...............1"])
        TpKill(g, BrickAt(g, 0, 0))
        Same(t, g.score, pair[1], pair[0] + ": a bomb's 25 points")
    end for
end sub

sub TestServe(t as object)
    g = TpNew("campaign", "normal", 3)
    Same(t, g.state, "ready", "a wall starts with the ball served")
    b = g.balls[0]
    Check(t, b.stuck, "the ball rests on the paddle")
    y = b.y
    TpTick(g, 500)
    Near(t, g.balls[0].y, y, 0.01, "it stays there")
    TpPress(g, "launch")
    Same(t, g.state, "play", "OK launches it")
    b = g.balls[0]
    Check(t, not b.stuck, "the ball is off the paddle")
    Check(t, b.vy < 0, "going up")
    Near(t, Sqr(b.vx * b.vx + b.vy * b.vy), 280, 0.5, "at the wall's speed")
    Check(t, Abs(b.vx) < 0.26 * 280, "nearly straight up from the middle")
    Check(t, HasEvent(g, "launch"), "the screen hears it")
end sub

sub TestPaddle(t as object)
    g = TpNew("campaign", "normal", 4)
    g.paddle.x = 0.0
    TpPress(g, "right")
    TpTick(g, 96)
    tap = g.paddle.x
    Check(t, tap > 36 and tap < 60, "a tap moves it a little, got " + Str(tap).Trim())
    TpTick(g, 704)
    x1 = g.paddle.x
    TpTick(g, 96)
    Near(t, g.paddle.x - x1, 1100 * 0.096, 2, "held, it goes 1100 a second at most")
    TpTick(g, 2000)
    Near(t, g.paddle.x, g.rules.w - g.paddle.w, 0.01, "it stops at the right side")
    TpRelease(g, "right")
    TpPress(g, "left")
    TpTick(g, 3000)
    Near(t, g.paddle.x, 0, 0.01, "and at the left side")
    TpRelease(g, "left")
    x2 = g.paddle.x
    TpTick(g, 500)
    Near(t, g.paddle.x, x2, 0.01, "letting go stops it")
end sub

sub TestPaddleRepeat(t as object)
    g = TpNew("campaign", "normal", 4)
    g.paddle.x = 0.0
    TpPress(g, "right")
    TpTick(g, 496)
    x1 = g.paddle.x
    TpPress(g, "right")
    TpTick(g, 96)
    Near(t, g.paddle.x - x1, 1100 * 0.096, 2, "still at full speed after the key comes again")
end sub

sub TestRide(t as object)
    g = TpNew("campaign", "normal", 5)
    p = g.paddle
    TpPress(g, "left")
    TpTick(g, 200)
    TpRelease(g, "left")
    b = g.balls[0]
    Near(t, b.x + g.rules.ball / 2, p.x + p.w / 2, 0.01, "the ball stays on the paddle's middle")
end sub

sub TestWallBounce(t as object)
    g = PlayGame("endless", "normal", EmptyRows(1))
    g.balls.Push(LooseBall(5, 300, -280, 0.0001))
    TpTick(g, 40)
    b = g.balls[1]
    Check(t, b.vx > 0, "off the left side")
    Check(t, b.x >= 0, "never past it")
    b.x = g.rules.w - 20
    b.vx = 280
    TpTick(g, 40)
    Check(t, b.vx < 0, "off the right side")
    Check(t, b.x + g.rules.ball <= g.rules.w, "never past it")
    b.y = 4
    b.vx = 0.0
    b.vy = -280
    TpTick(g, 40)
    Check(t, b.vy > 0, "off the top")
end sub

sub TestPaddleBounce(t as object)
    g = PlayGame("endless", "normal", EmptyRows(1))
    p = g.paddle
    p.x = 485.0
    ball = LooseBall(p.x + p.w / 2 - 7, 486, 0, 280)
    g.balls.Push(ball)
    TpTick(g, 24)
    Check(t, ball.vy < 0, "it goes back up")
    Near(t, ball.vx, 0, 0.5, "straight up from the middle")
    Near(t, ball.vy, -280, 0.5, "at the same speed")
    Check(t, HasEvent(g, "paddle"), "the screen hears the bounce")
    edge = LooseBall(p.x + p.w - 7, 486, 0, 280)
    g.balls.Push(edge)
    TpTick(g, 24)
    Near(t, edge.vx, 280 * Sin(1.0471976), 1, "60 degrees to the right at the right end")
    Near(t, edge.vy, -280 * Cos(1.0471976), 1, "and up")
end sub

sub TestBrick(t as object)
    g = PlayGame("endless", "normal", ["................", "................", "........1.......", "...............1"])
    k = BrickAt(g, 2, 8)
    ball = LooseBall(k.x + 10, k.y + g.rules.brickH + 12, 0, -280)
    g.balls.Push(ball)
    TpTick(g, 80)
    Check(t, not k.alive, "the brick is gone")
    Same(t, g.score, 10, "10 points")
    Check(t, ball.vy > 0, "the ball turns back down")
    Check(t, HasEvent(g, "brick"), "the screen hears it")
    Same(t, TpBricksLeft(g), 1, "one brick left")
end sub

sub TestBrickSeam(t as object)
    rows = ["...............1", "................", "................", "1111111111111111"]
    ' rising mostly under the right one of a pair: it turns back down off that one
    g = PlayGame("endless", "normal", rows)
    brickA = BrickAt(g, 3, 7)
    brickB = BrickAt(g, 3, 8)
    under = brickA.y + g.rules.brickH
    ball = LooseBall(brickA.x + g.brickW - 1, under + 0.5, 0, -280)
    g.balls.Push(ball)
    TpTick(g, 8)
    Check(t, ball.vy > 0, "it turns back down")
    Check(t, not brickB.alive and brickA.alive, "the brick it was mostly under goes, the other stays")
    TpTick(g, 200)
    Same(t, TpBricksLeft(g), 16, "one brick, no more")
    ' the fastest ball right under the gap's middle, going in deeper than it overlaps either
    g = PlayGame("endless", "hard", rows)
    brickA = BrickAt(g, 3, 7)
    gapMiddle = brickA.x + g.brickW + g.rules.gap / 2
    ball = LooseBall(gapMiddle - g.rules.ball / 2, under + 0.3, 0, -672)
    g.balls.Push(ball)
    TpTick(g, 8)
    Check(t, ball.vy > 0, "a fast one under the middle of the gap turns back down too")
    Same(t, TpBricksLeft(g), 16, "and one of the pair goes")
    TpTick(g, 200)
    Same(t, TpBricksLeft(g), 16, "no more")
end sub

sub TestBrickSide(t as object)
    g = PlayGame("endless", "normal", ["...............1", "................", "................", "........1......."])
    k = BrickAt(g, 3, 8)
    ball = LooseBall(k.x - g.rules.ball - 0.4, k.y + 4, 280, 14)
    g.balls.Push(ball)
    TpTick(g, 16)
    Check(t, not k.alive, "the brick goes")
    Check(t, ball.vx < 0, "the ball turns back the way it came")
    Check(t, ball.vy > 0, "still drifting down, as before")
end sub

sub TestBomb(t as object)
    rows = ["...............1", ".....111........", ".....1B1........", ".....11B........", "........1......."]
    g = PlayGame("endless", "normal", rows)
    TpKill(g, BrickAt(g, 2, 6))
    TpTick(g, 40)
    Check(t, BrickAt(g, 1, 5).alive, "not yet: the blast comes a moment later")
    TpTick(g, 16)
    allGone = true
    for each spot in [[1, 5], [1, 6], [1, 7], [2, 5], [2, 7], [3, 5], [3, 6], [3, 7]]
        if BrickAt(g, spot[0], spot[1]).alive then allGone = false
    end for
    Check(t, allGone, "the eight bricks around the bomb are gone")
    Check(t, BrickAt(g, 4, 8).alive, "the next bomb's blast is still to come")
    TpTick(g, 56)
    Check(t, not BrickAt(g, 4, 8).alive, "the bomb it hit went off in turn")
    Check(t, BrickAt(g, 0, 15).alive, "a brick far away is still there")
    Check(t, HasEvent(g, "bomb"), "the screen hears the blasts")
    Same(t, g.score, 25 + 7 * 10 + 25 + 10, "two bombs and eight bricks")
end sub

sub TestCapsule(t as object)
    g = PlayGame("endless", "normal", ["...............1", "M3.............."])
    g.paddle.x = 0.0
    TpKill(g, BrickAt(g, 1, 0))
    Same(t, g.capsules.Count(), 1, "the capsule drops")
    Same(t, g.capsules[0].kind, "multi", "it's the brick's capsule")
    TpTick(g, 3000)
    Same(t, g.capsules.Count(), 0, "it reached the paddle")
    Same(t, g.balls.Count(), 3, "two more balls")
    caught = ""
    for each e in g.events
        if e.kind = "catch" then caught = e.data
    end for
    Same(t, caught, "multi", "the screen hears the catch")
    ' one the paddle misses falls past
    g = PlayGame("endless", "normal", ["...............1", "W3.............."])
    g.paddle.x = 900.0
    TpKill(g, BrickAt(g, 1, 0))
    inside = true
    for n = 1 to 500
        TpTick(g, 8)
        for each cap in g.capsules
            if cap.y + g.rules.capsuleH > g.rules.h then inside = false
        end for
    end for
    Check(t, inside, "it is gone before any of it is below the field")
    Same(t, g.capsules.Count(), 0, "a missed capsule is gone")
    Near(t, g.paddle.w, 150, 0.01, "and did nothing")
end sub

sub TestWide(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    TpApply(g, "wide")
    Near(t, g.paddle.w, 225, 0.01, "150 becomes 225")
    Check(t, g.wide, "wide is on")
    g.balls = [LooseBall(500, 540, 0, 280)]
    TpTick(g, 100)
    Same(t, g.lives, 2, "the ball fell: a life gone")
    Near(t, g.paddle.w, 150, 0.01, "the paddle is back to its width")
    Check(t, not g.wide, "wide is off")
end sub

sub TestSticky(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    TpApply(g, "sticky")
    Same(t, g.stickyMs, 12000, "12 seconds")
    p = g.paddle
    p.x = 400.0
    ball = LooseBall(470, 470, 0, 280)
    g.balls = [ball]
    TpTick(g, 200)
    Check(t, ball.stuck, "the ball stays on the paddle")
    TpPress(g, "launch")
    Check(t, not ball.stuck and ball.vy < 0, "OK lets it go, upward")
    ' the time running out lets it go too
    g.stickyMs = 100
    ball.stuck = true
    ball.dx = 0.0
    ball.vx = 0.0
    ball.vy = 0.0
    TpTick(g, 120)
    Check(t, not ball.stuck and ball.vy < 0, "when sticky wears off, the ball goes")
    Same(t, g.stickyMs, 0, "and sticky is over")
    ' a ball that lands on the paddle's end stays there, and leaves at 60 degrees
    g.stickyMs = 12000
    edge = LooseBall(p.x + p.w - 7, 470, 0, 280)
    g.balls = [edge]
    TpTick(g, 200)
    Check(t, edge.stuck, "one landing at the end stays too")
    Near(t, edge.x + g.rules.ball / 2, p.x + p.w, 0.01, "right where it landed")
    TpPress(g, "launch")
    Near(t, edge.vx, 280 * Sin(1.0471976), 1, "it leaves 60 degrees to the right")
    Near(t, edge.vy, -280 * Cos(1.0471976), 1, "and up")
end sub

sub TestStickyMany(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    TpApply(g, "sticky")
    p = g.paddle
    p.x = 400.0
    caughtBall = LooseBall(470, 485, 0, 280)
    ballA = LooseBall(100, 300, 0, -280)
    ballB = LooseBall(900, 300, 0, -280)
    g.balls = [caughtBall, ballA, ballB]
    TpTick(g, 160)
    Same(t, g.balls.Count(), 3, "every ball is still there")
    Check(t, caughtBall.stuck, "the one that came down is on the paddle")
    Near(t, caughtBall.y, g.rules.paddleY - g.rules.ball - 1.0, 0.01, "resting on top of it")
    Near(t, caughtBall.x + g.rules.ball / 2, p.x + p.w / 2 + caughtBall.dx, 0.01, "where it landed")
    Check(t, not ballA.stuck and not ballB.stuck, "the others fly on")
    Check(t, ballA.y < 300 and ballB.y < 300, "still going up")
end sub

sub TestSlow(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    TpApply(g, "slow")
    Same(t, g.slowMs, 8000, "8 seconds")
    ball = LooseBall(500, 300, 0, -280)
    g.balls.Push(ball)
    TpTick(g, 96)
    Near(t, 300 - ball.y, 280 * 0.096 * 0.6, 0.5, "0.6 times as far")
    Same(t, g.slowMs, 8000 - 96, "the time runs down")
    g.slowMs = 50
    TpTick(g, 56)
    Same(t, g.slowMs, 0, "and runs out")
    y = ball.y
    TpTick(g, 96)
    Near(t, y - ball.y, 280 * 0.096, 0.5, "then as far as before")
end sub

sub TestMulti(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    g.balls = [LooseBall(500, 300, 0, -280)]
    TpApply(g, "multi")
    Same(t, g.balls.Count(), 3, "three balls")
    a = TpAtan2(g.balls[1].vy, g.balls[1].vx)
    Near(t, a, -1.5707963 - 0.4, 0.01, "one 0.4 to the left of the first's way")
    for i = 1 to 3
        TpApply(g, "multi")
    end for
    Same(t, g.balls.Count(), 6, "six at most")
    for each b in g.balls
        Near(t, b.speed, 280, 0.5, "every ball at the same speed")
    end for
end sub

sub TestLifeAndMystery(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    TpApply(g, "life")
    Same(t, g.lives, 4, "a life more")
    kinds = {}
    for n = 1 to 200
        g = PlayGame("endless", "normal", ["...............1", "P3.............."])
        g.rng = GameRng(1000 + n)
        TpKill(g, BrickAt(g, 1, 0))
        kinds[g.capsules[0].kind] = true
    end for
    for each kind in kinds
        Check(t, Instr(1, "|multi|wide|sticky|slow|life|", "|" + kind + "|") > 0, "a mystery is one of the five: " + kind)
    end for
    Same(t, kinds.Count(), 5, "every kind comes up")
end sub

sub TestLives(t as object)
    g = PlayGame("endless", "normal", ["...............1"])
    ' a ball just above the bottom, going down: one step and part of it would be past
    g.balls = [LooseBall(500, g.rules.h - g.rules.ball - 1, 0, 280)]
    g.capsules.Push({ x: 900.0, y: 100.0, kind: "wide" })
    TpTick(g, 8)
    Same(t, g.lives, 2, "a life gone as soon as the ball starts to leave the field")
    Same(t, g.capsules.Count(), 0, "the falling capsules go with it")
    Same(t, g.state, "ready", "the ball is served again")
    Check(t, g.balls[0].stuck, "on the paddle")
    Check(t, HasEvent(g, "life"), "the screen hears it")
    g.lives = 1
    TpPress(g, "launch")
    g.balls = [LooseBall(500, 540, 0, 280)]
    TpTick(g, 100)
    Same(t, g.lives, 0, "no lives left")
    Same(t, g.state, "over", "the run is over")
    x = g.paddle.x
    TpPress(g, "right")
    TpTick(g, 500)
    Near(t, g.paddle.x, x, 0.01, "nothing moves after the end")
end sub

sub TestClear(t as object)
    g = TpNew("campaign", "normal", 6)
    TpPress(g, "launch")
    TpApply(g, "wide")
    TpApply(g, "sticky")
    TpApply(g, "slow")
    g.capsules.Push({ x: 900.0, y: 100.0, kind: "life" })
    for each k in g.bricks
        k.alive = false
    end for
    TpCheckClear(g)
    Same(t, g.state, "clear", "the wall is cleared")
    Same(t, g.balls.Count(), 0, "the balls are put away")
    Same(t, g.capsules.Count(), 0, "and the falling capsules")
    TpPress(g, "launch")
    Same(t, g.wall, 1, "OK: the second wall")
    Same(t, g.state, "ready", "with the ball served")
    Check(t, TpBricksLeft(g) > 0, "and its bricks up")
    Near(t, TpSpeed(g), 280 * 1.1, 0.5, "a little faster")
    Near(t, g.paddle.w, 150, 0.01, "the paddle back to its own width")
    Check(t, not g.wide, "wide is off")
    Same(t, g.stickyMs, 0, "sticky is off")
    Same(t, g.slowMs, 0, "slow is off")
    TpStartWall(g, 5)
    TpPress(g, "launch")
    for each k in g.bricks
        k.alive = false
    end for
    TpCheckClear(g)
    Same(t, g.state, "won", "the sixth wall ends the campaign")
    ' the last brick going while another ball flies: every ball is put away
    g = PlayGame("endless", "normal", ["................", "................", "........1......."])
    k = BrickAt(g, 2, 8)
    g.balls = [LooseBall(k.x + 10, k.y + g.rules.brickH + 1, 0, -280), LooseBall(200, 300, 0, -280)]
    TpTick(g, 40)
    Same(t, g.state, "clear", "the last brick clears the wall")
    Same(t, g.balls.Count(), 0, "even the ball still flying is put away")
end sub

sub TestEndless(t as object)
    g = TpNew("endless", "normal", 7)
    Near(t, TpSpeed(g), 280, 0.5, "the first wall at the base speed")
    g.wall = 10
    Near(t, TpSpeed(g), 420, 0.5, "5 in 100 faster each wall")
    g.wall = 40
    Near(t, TpSpeed(g), 560, 0.5, "never more than twice")
    for n = 1 to 30
        rows = TpEndlessWall(g, n)
        text = JoinRows(rows)
        wantRows = 5 + (n - 1) \ 2
        if wantRows > 9 then wantRows = 9
        Same(t, rows.Count(), wantRows, "wall " + n.ToStr() + " rows")
        across = Len(rows[0])
        Check(t, across >= 16 and across <= 20 and across mod 2 = 0, "wall " + n.ToStr() + " is 16 to 20 across")
        if n < 4 then Same(t, across, 16, "the first three walls are 16 across")
        Check(t, CountChars(text, "MWSZLP") >= 1, "wall " + n.ToStr() + " has a capsule")
        Check(t, Len(text) - CountChars(text, ".") >= 16, "wall " + n.ToStr() + " has bricks")
    end for
    ' from wall 10 on: about 3 capsules and 14 bombs in every 100 bricks
    g = TpNew("endless", "normal", 77)
    bricks = 0
    caps = 0
    bombs = 0
    for n = 11 to 40
        text = JoinRows(TpEndlessWall(g, n))
        bricks = bricks + Len(text) - CountChars(text, ".")
        caps = caps + CountChars(text, "MWSZLP")
        bombs = bombs + CountChars(text, "B")
    end for
    capShare = caps / bricks
    bombShare = bombs / bricks
    Check(t, capShare > 0.02 and capShare < 0.05, "capsules about 3 in 100, got " + Str(capShare * 100).Trim())
    Check(t, bombShare > 0.11 and bombShare < 0.17, "bombs about 14 in 100, got " + Str(bombShare * 100).Trim())
end sub

sub TestSeed(t as object)
    a = TpNew("endless", "normal", 31)
    b = TpNew("endless", "normal", 31)
    c = TpNew("endless", "normal", 32)
    sameAB = true
    sameAC = true
    for n = 1 to 10
        ra = JoinRows(TpEndlessWall(a, n))
        rb = JoinRows(TpEndlessWall(b, n))
        rc = JoinRows(TpEndlessWall(c, n))
        if ra <> rb then sameAB = false
        if ra <> rc then sameAC = false
    end for
    Check(t, sameAB, "the same seed builds the same ten walls")
    Check(t, not sameAC, "another seed builds others")
end sub

' Straight up at the fastest speed into a full row, from start heights that put the ball at
' every point of an 8 ms step when it reaches the row: it never gets past the row's underside.
sub TestNoTunnel(t as object)
    rows = ["................", "................", "1111111111111111", "...............1"]
    g = PlayGame("endless", "hard", rows)
    g.wall = 60
    Near(t, TpSpeed(g), 672, 0.5, "the fastest ball: twice the speed, hard")
    for each y0 in [300.0, 302.0, 305.0, 310.0, 320.0, 333.0]
        g = PlayGame("endless", "hard", rows)
        ball = LooseBall(500, y0, 0, -672)
        g.balls.Push(ball)
        under = g.rules.brickTop + 2 * (g.rules.brickH + g.rules.gap) + g.rules.brickH
        highest = y0
        for n = 1 to 125
            TpTick(g, 8)
            if ball.y < highest then highest = ball.y
            if ball.vy > 0 then exit for
        end for
        startText = "from y " + Str(y0).Trim() + ": "
        Check(t, highest >= under - 0.01, startText + "it never got past the row's underside, got to " + Str(highest).Trim())
        Same(t, g.score, 15, startText + "it hit the row (one brick, hard's points)")
        Check(t, ball.vy > 0, startText + "and came back down")
    end for
end sub

' The demo, checked after every move: no ball inside a standing brick, nothing outside the field.
sub TestDemo(t as object)
    d = TpDemoNew(4242)
    best = 0
    walls = 0
    inBrick = 0
    outside = 0
    for n = 1 to 3000
        TpDemoStep(d, 100)
        g = d.g
        r = g.rules
        if g.score > best then best = g.score
        if g.wall > walls then walls = g.wall
        for each b in g.balls
            if b.x < 0 or b.y < 0 or b.x + r.ball > r.w or b.y + r.ball > r.h then outside = outside + 1
            for each k in g.bricks
                if k.alive then
                    if b.x + r.ball > k.x and b.x < k.x + g.brickW and b.y + r.ball > k.y and b.y < k.y + r.brickH then inBrick = inBrick + 1
                end if
            end for
        end for
        for each cap in g.capsules
            if cap.y + r.capsuleH > r.h then outside = outside + 1
        end for
    end for
    Check(t, best > 200, "the demo knocks bricks out, best " + best.ToStr())
    Check(t, d.g.events.Count() <= 40, "the demo doesn't pile up events")
    Same(t, inBrick, 0, "times a ball was inside a brick")
    Same(t, outside, 0, "times something was outside the field")
    print "    (demo: best "; best.ToStr(); " points, reached wall "; (walls + 1).ToStr(); ")"
end sub
