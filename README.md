# b0r3d TV

A home screen for Roku TVs that looks like an old cable box, made by [b0r3d.org](https://b0r3d.org).

Your apps and a couple of b0r3d games each get a channel in a retro channel guide, and you flip through them with the Roku remote.

It comes in four looks:

- **Late-night cable guide:** a blue grid of channels with a preview window
- **b0r3d 95:** a desktop with a channel guide window
- **Phosphor terminal:** one glowing color on black, with scanlines
- **VCR menu:** an on-screen menu with a picture-in-picture box

And two games: **Stuck Pixels**, a falling-block game, and **Test Pattern**, a brick breaker.

## Status

0.4 is a test build. Every app on your TV gets a channel, and the guide remembers the channel you opened last. Settings (the ✱ key) picks the look (the late-night cable guide, b0r3d 95 on a teal, blue or slate desktop, the phosphor terminal in green, amber or cyan, or the VCR menu in blue, black or green), shows, hides and reorders the channels, and sets the clock, the sound, the screensaver and the screen size. Its TV check page shows what your TV allows. Opening a channel tunes in with a burst of static and the channel's banner. The two games are on channels 20 and 21: Stuck Pixels and Test Pattern.

Roku TVs don't let an app switch the TV's inputs. [TVFollow](https://github.com/still-b0r3d/TVFollow) can do it for b0r3d TV: with TVFollow 1.3 (coming soon) running on your PC and **Let the app switch the TV's inputs** ticked in its developer tools, your TV's inputs (HDMI, the antenna) show up as channels a few seconds after b0r3d TV opens, and opening one switches the TV. Without TVFollow, b0r3d TV leaves the inputs to Roku's own home screen. And when you leave an app you opened from b0r3d TV, the TV goes to Roku's home screen, not back to b0r3d TV. To come back quickly, move b0r3d TV to the first spot on the home screen: highlight it there, press ✱ and move it.

## Stuck Pixels

A falling-block game on channel 20, drawn in whichever look you picked. The well is a small TV, 12 pixels wide and 18 tall, and the pieces are clusters of 3 and 5 pixels, all in the look's one colour. Fill a row from side to side and it clears.

Now and then a piece comes with a stuck pixel in it, flickering. Its row has to be filled twice: the first time, the stuck pixel pops out for extra points and leaves a hole; fill that, and the row clears. When the pile reaches the top, the little TV loses its signal.

- **Marathon:** 10 lines a level, faster each level, until the signal goes
- **Sprint 40:** 40 lines against the clock
- **Cleanup:** 25 lines, starting over rows of TV static

Each mode keeps its top 10 on the TV, with three-letter initials. Settings → High scores clears them (it asks first). When channel 20 is highlighted in the guide, its preview plays a demo. Rukus comes on only while the game is paused or on its menus.

## Test Pattern

A brick breaker on channel 21, on a field as wide as the TV. Every wall is a TV test card's colour bars, the ball is a square pixel, and the paddle speeds up the longer you hold a direction. Bricks of static are bombs that blow up the bricks around them, and bricks with a little TV on them drop a capsule, a little TV of its own: two more balls, a wider paddle, a sticky paddle for 12 seconds, a slower ball for 8 seconds, a life, or a surprise.

- **Campaign:** six walls, each a little faster than the last
- **Endless:** new walls that never stop, faster each time up to twice the speed
- **Easy, normal or hard:** 5, 3 or 2 lives, a wider or narrower paddle, a slower or faster ball, and half, normal or one and a half times the points

Each mode keeps its top 10 on the TV, with initials, and its preview in the guide plays a demo. As in Stuck Pixels, Rukus comes on only while the game is paused or on its menus.

## The screensaver

Rukus wanders a dark screen: he walks on, sits, grooms, loafs, naps, stretches, chases a stuck pixel now and then, and wanders off. A clock in the look's lettering drifts slowly, so nothing stays in one spot.

- **On the whole TV:** pick **b0r3d TV** in the TV's Settings → Theme → Screensavers. It comes on whenever the TV sits idle outside b0r3d TV.
- **Inside b0r3d TV:** Roku shows no screensaver over an app drawn like b0r3d TV; at the TV's screensaver time the screen just goes black. So b0r3d TV brings Rukus on itself, 30 seconds before that time, and any key brings back the screen you were on. Settings → Screensaver picks what happens at the TV's time: b0r3d TV keeps the TV awake so Rukus stays on (with an old Roku call that resets the TV's idle clock, for up to 2 hours), hands over to the TV's own screensaver, or lets the screen go black. Settings → Screensaver check shows how each of those went on your TV.

## The remote

- **Up and down:** move through the channels
- **Rewind and fast-forward:** a page at a time
- **OK:** open the channel
- **Replay:** jump back to the channel you opened before, like a cable remote's LAST key
- **✱:** Settings
- **Back:** leave b0r3d TV
- **Any key while Rukus is on:** back to the screen you were on

In Stuck Pixels:

- **Left and right:** move the piece (hold one to slide)
- **Down:** drop faster while held
- **Up:** drop it all the way
- **OK or fast-forward:** turn right; **rewind:** turn left
- **Replay:** put the piece on hold, or swap it back (once a piece)
- **Play, Back or ✱:** pause, with a menu to carry on, start again or go back to the guide

In Test Pattern:

- **Left and right:** move the paddle while held; it speeds up the longer you hold
- **OK:** serve the ball, let go of a stuck one, or go on to the next wall
- **Play, Back or ✱:** pause, with the same menu

## Trying it

b0r3d TV installs through Roku's developer mode, which lets a TV hold one app you add yourself. It won't be in Roku's store.

1. Turn on developer mode on your Roku TV (Roku's developer documentation shows how).
2. Zip everything inside the `app` folder, so `manifest` sits at the top of the zip.
3. In a browser, open your TV's address (the TV shows it in Settings → Network → About), sign in as `rokudev` with the password you chose, and install the zip.

## What's here

- `app/`: the Roku app: `manifest`, the BrightScript code in `source/`, the stand-in screen in `components/` (shown while b0r3d TV hands over to the TV's own screensaver), the pictures in `images/`, the fonts in `fonts/` and the sounds in `sounds/`
- `tools/make-images.js`: makes the home-screen tile and the splash picture (`node tools/make-images.js`)
- `tools/make-sounds.js`: makes the burst of static heard when a channel opens and the games' sounds (`node tools/make-sounds.js`)
- `tools/font-family-names.js`: the one change made to the Barlow Condensed files (see License)
- `tests/stuck-tests.brs`, `tests/tp-tests.brs` and `tools/test-games.sh`: the games' rules played on a PC by a BrightScript simulator (brs-node), test by test (`bash tools/test-games.sh`)
- `tools/check.sh` and `.github/workflows/check.yml`: the check every push to main gets (the app compiles, the games' rules pass their tests, every commit carries the project's name, nothing private slipped in)

## License

The code is under the MIT License with the Commons Clause: you can use and change it, but not sell it. See [LICENSE](LICENSE).

Rukus and the rest of the art, sound and writing are all rights reserved. See [LICENSE-ASSETS](LICENSE-ASSETS).

The fonts in `app/fonts` are Barlow Condensed, VT323, Silkscreen and W95FA, free fonts under the SIL Open Font License 1.1. Each folder holds the font's license and copyright in `OFL.txt`, except W95FA, whose license file came with no copyright filled in: its `README.txt` names the maker. Neither notice above covers the fonts. The Medium, SemiBold and ExtraBold files of Barlow Condensed have one change: their shared family name is taken out, so a Roku keeps each weight apart (`tools/font-family-names.js` makes that change).
