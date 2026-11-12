# b0r3d TV

A home screen for Roku TVs that looks like an old cable box, made by [b0r3d.org](https://b0r3d.org).

Your apps and b0r3d's own channels each get a channel in a retro channel guide, and you flip through them with the Roku remote.

It comes in five looks:

- **Late-night cable guide:** a blue grid of channels with a preview window
- **b0r3d 95:** a desktop with a channel guide window
- **Phosphor terminal:** one glowing color on black, with scanlines
- **VCR menu:** an on-screen menu with a picture-in-picture box
- **RGB LED lights:** a TV on a dark wall, lit from behind by colour-changing LEDs

b0r3d's own channels are a **VCR**, **Rukus Cam** (a camera on Rukus's room), three games, **Stuck Pixels** (a falling-block game), **Test Pattern** (a brick breaker) and **Snake**, a radio station, **b0r3d FM**, and **Commercial Breaks**, late-night ads for b0r3d's games.

## Status

0.71 is a test build. Every app on your TV gets a channel, and the guide remembers the channel you opened last. Its ON NOW column lists a made-up late-night show for each channel, changing every half hour. Settings (the ✱ key) picks the look (the late-night cable guide, b0r3d 95 on a teal, blue or slate desktop, the phosphor terminal in green, amber or cyan, the VCR menu in blue, black or green, or the RGB LED lights in four colourways), shows, hides and reorders the channels, and sets the clock, the sound, the screensaver and the screen size. Its TV check page shows what your TV allows. Opening a channel tunes in with a burst of static and the channel's banner. b0r3d's own channels are 3, 9 and 20 to 24: the VCR, Rukus Cam, Stuck Pixels, Test Pattern, b0r3d FM, Snake and Commercial Breaks. Each one's preview box in the guide plays a demo of it, or for the VCR a small copy of its screen, and for Rukus Cam the camera's live picture.

Roku TVs don't let an app switch the TV's inputs. [TVFollow](https://github.com/still-b0r3d/TVFollow) can do it for b0r3d TV: with TVFollow 1.3 (coming soon) running on your PC and **Let the app switch the TV's inputs** ticked in its developer tools, your TV's inputs (HDMI, the antenna) show up as channels a few seconds after b0r3d TV opens, and opening one switches the TV. Without TVFollow, b0r3d TV leaves the inputs to Roku's own home screen. And when you leave an app you opened from b0r3d TV, the TV goes to Roku's home screen, not back to b0r3d TV. To come back quickly, move b0r3d TV to the first spot on the home screen: highlight it there, press ✱ and move it.

## VCR

A VCR on channel 3, where old VCRs played. It has no tape yet: its blue screen says STOP and NO TAPE, and its clock blinks 12:00, the time nobody ever set. It looks the same in every look.

A tape goes in with the launch parameter `tape`, set to a video's address: an `http://` or `https://` address of up to 2000 characters, of an MP4 file or of an HLS stream ending in `.m3u8`. Sent while b0r3d TV is open (as an input command), it does the same. The VCR comes on and plays the tape full screen, showing PLAY and the tape counter for 5 seconds. The tape isn't kept: when b0r3d TV closes, it's gone. Like b0r3d FM, the VCR keeps Rukus away while a tape plays, and keeps the TV awake only with Settings → Screensaver on its first pick.

## Rukus Cam

A security camera on Rukus's room, on channel 9 (a cat has nine lives). It's live: Rukus walks about, sits, grooms, loafs, naps, stretches, wanders off and comes back, and now and then chases a stuck pixel, as he does in the screensaver. The window shows the time of day by the TV's clock: sunrise from 6, daylight from 8 with the sun lying on the floor, sunset from 17, and from 20 the camera switches to infrared, with the moon out and his eyes shining. CAM 1, a blinking REC and the date and time sit over the picture, as on a real camera. It looks the same in every look.

OK throws Rukus a treat from the camera, one at a time, nine a day. He drops whatever he's doing, even a nap or a stroll out of the room, dashes for it and crunches it. Like b0r3d FM, Rukus Cam keeps the screensaver away (Rukus is on already), and keeps the TV awake only with Settings → Screensaver on its first pick.

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

## Snake

Snake on channel 23: a 20 by 20 arena whose edges wrap round to the other side. Each bite makes the snake one longer and a little faster, down to 70 ms a step, and biting yourself ends the run. It keeps its top 10 on the TV, with initials, and Rukus comes on only while it's paused or on its menus.

## b0r3d FM

A radio station on channel 22: b0r3d's songs, streamed from b0r3d.download one after another, with bars that move to them and Rukus listening. OK or Play pauses and carries on, left and right (or rewind and fast-forward) skip. With no network the station stops after a few tries and says so; OK tries again. While it plays, Rukus stays away until it's paused. With Settings → Screensaver on its first pick (Rukus, keeping the TV awake), b0r3d TV keeps the TV awake while it plays; with the other picks the screen goes black at the TV's screensaver time.

## Commercial Breaks

Late-night ads on channel 24, a new one every 8 seconds: b0r3d's games and a public service announcement. Left and right skip, OK or Play pauses. Like b0r3d FM, it keeps Rukus away while it plays, and keeps the TV awake only with Settings → Screensaver on its first pick.

## Online high scores

A score that makes a game's top 10 on the TV also goes to b0r3d's online boards at still.b0r3d.org, each game with boards of its own (Stuck Pixels' Marathon, Test Pattern's two modes, and Snake). What's sent is the three initials and the score, with a run token the board handed out when the run began; the request names b0r3d TV and its version. A game's high-score page asks for its board's table when it opens; up and down switch between the TV's table and the online one.

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

In Snake:

- **Up, down, left and right:** steer
- **Play, Back or ✱:** pause, with the same menu

On b0r3d FM and Commercial Breaks:

- **OK or Play:** pause, and carry on from the same spot
- **Left and right, rewind and fast-forward:** skip (on b0r3d FM, up and down too)
- **Back:** back to the guide

On the VCR:

- **OK or Play:** pause, and carry on; at the end of the tape, or after NO SIGNAL, play it again
- **✱:** show or hide PLAY and the tape counter
- **Back:** stop the tape and go back to the guide

On Rukus Cam:

- **OK:** throw Rukus a treat (one at a time, nine a day)
- **Back:** back to the guide

On a game's high-score page, **up and down** switch between the TV's table and the online one.

## Trying it

b0r3d TV installs through Roku's developer mode, which lets a TV hold one app you add yourself. It won't be in Roku's store.

1. Turn on developer mode on your Roku TV (Roku's developer documentation shows how).
2. Zip everything inside the `app` folder, so `manifest` sits at the top of the zip.
3. In a browser, open your TV's address (the TV shows it in Settings → Network → About), sign in as `rokudev` with the password you chose, and install the zip.

## What's here

- `app/`: the Roku app: `manifest`, the BrightScript code in `source/`, the stand-in screen in `components/` (shown while b0r3d TV hands over to the TV's own screensaver), the pictures in `images/`, the fonts in `fonts/` and the sounds in `sounds/`. A local git hook writes the commit's short hash into `app/build.txt`, which the build line shows (`Build: abc1234`); the file stays out of the repo, and without it the build says `dev`.
- `tools/make-images.js`: makes the home-screen tile and the splash picture (`node tools/make-images.js`)
- `tools/make-sounds.js`: makes the burst of static heard when a channel opens and the games' sounds (`node tools/make-sounds.js`)
- `tools/make-rgb-light.js`: makes the RGB look's pictures in `app/images/rgb/`: the soft glows round the TV and the Settings panel, the LED colour strips, the focused row's light, the TV badge, the remote's keys and the arrows (`node tools/make-rgb-light.js`)
- `tools/font-family-names.js`: the one change made to the Barlow Condensed files (see License)
- `tests/stuck-tests.brs`, `tests/tp-tests.brs`, `tests/snake-tests.brs` and `tools/test-games.sh`: the games' rules played on a PC by a BrightScript simulator (brs-node), test by test (`bash tools/test-games.sh`)
- `tools/check.sh` and `.github/workflows/check.yml`: the check every push to main gets (the app compiles, the games' rules pass their tests, every commit carries the project's name, nothing private slipped in)

## License

The code is under the MIT License with the Commons Clause: you can use and change it, but not sell it. See [LICENSE](LICENSE).

Rukus and the rest of the art, sound and writing are all rights reserved. See [LICENSE-ASSETS](LICENSE-ASSETS).

The fonts in `app/fonts` are Barlow Condensed, VT323, Silkscreen and W95FA, free fonts under the SIL Open Font License 1.1. Each folder holds the font's license and copyright in `OFL.txt`, except W95FA, whose license file came with no copyright filled in: its `README.txt` names the maker. Neither notice above covers the fonts. The Medium, SemiBold and ExtraBold files of Barlow Condensed have one change: their shared family name is taken out, so a Roku keeps each weight apart (`tools/font-family-names.js` makes that change).
