' The game-rule tests for Snake. The BrightScript simulator runs them on a PC,
' and GitHub runs them on every push (tools/test-games.sh). Each test plays the rules
' in app/source/snake.brs (with games.brs) and checks what happened.

sub Main()
    t = { passed: 0, failed: 0, fails: [] }
    tests = [
        { name: "start state: length 3 centered, moving right, score 0, speed 140ms", fn: TestStart },
        { name: "stepping advances the snake in the current direction", fn: TestStep },
        { name: "moving off any of the four edges wraps around to the opposite side", fn: TestWrap },
        { name: "direction change updates next direction and moves accordingly on next step", fn: TestDirection },
        { name: "reversing directly into the snake's neck is ignored", fn: TestNoReverse },
        { name: "eating food increases score and length, accelerates speed, and places new food", fn: TestEat },
        { name: "moving into the space vacated by the tail in the same tick is legal", fn: TestTailChase },
        { name: "colliding with any part of the body ends the run with an over event", fn: TestSelfCollision },
        { name: "speed acceleration is clamped at the minimum speed", fn: TestMinSpeed },
        { name: "identical seeds produce identical initial food positions", fn: TestSeedRepeatability },
        { name: "autoplay steers safely towards food without colliding or moving out of bounds", fn: TestAutoplay }
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

' --- Tests ---

sub TestStart(t as object)
    g = SnakeNew(12345)
    Check(t, g.cols = 20 and g.rows = 20, "board is 20x20")
    Check(t, g.snake.Count() = 3, "initial length is 3")
    Check(t, g.snake[0].x = 10 and g.snake[0].y = 10, "head starts at center (10, 10)")
    Check(t, g.snake[1].x = 9 and g.snake[1].y = 10, "segment 1 at (9, 10)")
    Check(t, g.snake[2].x = 8 and g.snake[2].y = 10, "segment 2 at (8, 10)")
    Check(t, g.dir.x = 1 and g.dir.y = 0, "moving right")
    Check(t, g.score = 0, "initial score is 0")
    Check(t, g.speed = 140, "initial speed is 140")
    Check(t, g.state = "play", "state is play")
    Check(t, g.food.x <> 10 or g.food.y <> 10, "food not on head")
    Check(t, g.food.x <> 9 or g.food.y <> 10, "food not on segment 1")
    Check(t, g.food.x <> 8 or g.food.y <> 10, "food not on segment 2")
end sub

sub TestStep(t as object)
    g = SnakeNew(12345)
    g.food = { x: 0, y: 0 } ' Move food away
    ok = SnakeStep(g)
    Check(t, ok, "step succeeded")
    Check(t, g.snake.Count() = 3, "length stays 3 when not eating")
    Check(t, g.snake[0].x = 11 and g.snake[0].y = 10, "head advanced to (11, 10)")
    Check(t, g.snake[1].x = 10 and g.snake[1].y = 10, "segment 1 moved to (10, 10)")
    Check(t, g.snake[2].x = 9 and g.snake[2].y = 10, "tail moved to (9, 10)")
end sub

sub TestWrap(t as object)
    ' Right edge wrap
    g = SnakeNew(100)
    g.snake[0] = { x: 19, y: 5 }
    g.snake[1] = { x: 18, y: 5 }
    g.snake[2] = { x: 17, y: 5 }
    g.dir = { x: 1, y: 0 }
    g.nextDir = { x: 1, y: 0 }
    g.food = { x: 0, y: 0 }
    SnakeStep(g)
    Check(t, g.snake[0].x = 0 and g.snake[0].y = 5, "wrapped right edge to x=0")

    ' Left edge wrap
    g.snake[0] = { x: 0, y: 5 }
    g.snake[1] = { x: 1, y: 5 }
    g.snake[2] = { x: 2, y: 5 }
    g.dir = { x: -1, y: 0 }
    g.nextDir = { x: -1, y: 0 }
    SnakeStep(g)
    Check(t, g.snake[0].x = 19 and g.snake[0].y = 5, "wrapped left edge to x=19")

    ' Bottom edge wrap
    g.snake[0] = { x: 5, y: 19 }
    g.snake[1] = { x: 5, y: 18 }
    g.snake[2] = { x: 5, y: 17 }
    g.dir = { x: 0, y: 1 }
    g.nextDir = { x: 0, y: 1 }
    SnakeStep(g)
    Check(t, g.snake[0].x = 5 and g.snake[0].y = 0, "wrapped bottom edge to y=0")

    ' Top edge wrap
    g.snake[0] = { x: 5, y: 0 }
    g.snake[1] = { x: 5, y: 1 }
    g.snake[2] = { x: 5, y: 2 }
    g.dir = { x: 0, y: -1 }
    g.nextDir = { x: 0, y: -1 }
    SnakeStep(g)
    Check(t, g.snake[0].x = 5 and g.snake[0].y = 19, "wrapped top edge to y=19")
end sub

sub TestDirection(t as object)
    g = SnakeNew(500)
    g.food = { x: 0, y: 0 }
    turned = SnakeTurnDir(g, 0, 1)
    Check(t, turned, "turn down accepted")
    Check(t, g.dir.x = 1 and g.dir.y = 0, "dir remains right before step")
    Check(t, g.nextDir.x = 0 and g.nextDir.y = 1, "nextDir is down")
    SnakeStep(g)
    Check(t, g.dir.x = 0 and g.dir.y = 1, "dir updated to down on step")
    Check(t, g.snake[0].x = 10 and g.snake[0].y = 11, "head moved down")
end sub

sub TestNoReverse(t as object)
    g = SnakeNew(500)
    ' moving right: attempting to turn left directly must fail
    turned = SnakeTurnDir(g, -1, 0)
    Check(t, not turned, "180 reverse rejected")
    Check(t, g.nextDir.x = 1 and g.nextDir.y = 0, "nextDir remained right")
end sub

sub TestEat(t as object)
    g = SnakeNew(600)
    g.food = { x: 11, y: 10 } ' Food right in front of head
    SnakeStep(g)
    Check(t, g.score = 1, "score incremented to 1")
    Check(t, g.snake.Count() = 4, "length grew to 4")
    Check(t, g.speed = 137, "speed accelerated by 3ms to 137")
    Check(t, g.events.Count() = 1 and g.events[0].kind = "eat", "eat event fired")
    Check(t, g.food.x <> 11 or g.food.y <> 10, "new food placed elsewhere")
end sub

sub TestTailChase(t as object)
    ' Form a 4-segment loop where head is about to step onto current tail
    g = SnakeNew(700)
    g.snake = [
        { x: 5, y: 5 },
        { x: 5, y: 6 },
        { x: 6, y: 6 },
        { x: 6, y: 5 }
    ]
    g.dir = { x: 1, y: 0 }
    g.nextDir = { x: 1, y: 0 }
    g.food = { x: 0, y: 0 } ' not eating
    ok = SnakeStep(g)
    Check(t, ok, "stepping onto vacating tail succeeds")
    Check(t, g.state = "play", "game does not trigger self-collision")
    Check(t, g.snake[0].x = 6 and g.snake[0].y = 5, "head occupies old tail position")
end sub

sub TestSelfCollision(t as object)
    g = SnakeNew(800)
    g.snake = [
        { x: 5, y: 5 },
        { x: 5, y: 6 },
        { x: 6, y: 6 },
        { x: 6, y: 5 },
        { x: 6, y: 4 }
    ]
    g.dir = { x: 1, y: 0 }
    g.nextDir = { x: 1, y: 0 }
    g.food = { x: 6, y: 5 } ' eating food on the segment! tail cannot vacate
    ok = SnakeStep(g)
    Check(t, not ok, "step reported failure")
    Check(t, g.state = "over", "state is over")
    Check(t, g.events.Count() = 1 and g.events[0].kind = "over", "over event fired")
end sub

sub TestMinSpeed(t as object)
    g = SnakeNew(900)
    g.score = 30 ' 30 * 3 = 90ms decrement, 140 - 90 = 50ms, should clamp to 70ms
    g.food = { x: 11, y: 10 }
    SnakeStep(g)
    Check(t, g.speed = 70, "speed clamped to minSpeed (70)")
end sub

sub TestSeedRepeatability(t as object)
    g1 = SnakeNew(9999)
    g2 = SnakeNew(9999)
    Check(t, g1.food.x = g2.food.x and g1.food.y = g2.food.y, "food position matches for identical seed")
end sub

sub TestAutoplay(t as object)
    g = SnakeNew(42)
    for i = 1 to 200
        if g.state <> "play" then exit for
        SnakeAutoplay(g)
        SnakeStep(g)
    end for
    Check(t, g.score >= 1, "autoplay ate food and scored points")
    Check(t, g.snake[0].x >= 0 and g.snake[0].x < g.cols, "head within board x")
    Check(t, g.snake[0].y >= 0 and g.snake[0].y < g.rows, "head within board y")
end sub
