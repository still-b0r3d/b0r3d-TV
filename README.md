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

0.25 is a test build. Every app on your TV gets a channel, and the guide remembers the channel you opened last. Settings (the ✱ key) picks the look (the late-night cable guide, b0r3d 95 on a teal, blue or slate desktop, the phosphor terminal in green, amber or cyan, or the VCR menu in blue, black or green), shows, hides and reorders the channels, and sets the clock, the sound and the screen size. Its TV check page shows what your TV allows. Opening a channel tunes in with a burst of static and the channel's banner. The Rukus screensaver and the games come next.

Roku TVs don't let an app switch the TV's inputs. [TVFollow](https://github.com/still-b0r3d/TVFollow) can do it for b0r3d TV: with TVFollow 1.3 (coming soon) running on your PC and **Let the app switch the TV's inputs** ticked in its developer tools, your TV's inputs (HDMI, the antenna) show up as channels a few seconds after b0r3d TV opens, and opening one switches the TV. Without TVFollow, b0r3d TV leaves the inputs to Roku's own home screen. And when you leave an app you opened from b0r3d TV, the TV goes to Roku's home screen, not back to b0r3d TV. To come back quickly, move b0r3d TV to the first spot on the home screen: highlight it there, press ✱ and move it.

## The remote

- **Up and down:** move through the channels
- **Rewind and fast-forward:** a page at a time
- **OK:** open the channel
- **Replay:** jump back to the channel you opened before, like a cable remote's LAST key
- **✱:** Settings
- **Back:** leave b0r3d TV

## Trying it

b0r3d TV installs through Roku's developer mode, which lets a TV hold one app you add yourself. It won't be in Roku's store.

1. Turn on developer mode on your Roku TV (Roku's developer documentation shows how).
2. Zip everything inside the `app` folder, so `manifest` sits at the top of the zip.
3. In a browser, open your TV's address (for example `http://192.168.1.20`), sign in as `rokudev` with the password you chose, and install the zip.

## What's here

- `app/`: the Roku app: `manifest`, the BrightScript code in `source/`, the pictures in `images/`, the fonts in `fonts/` and the sounds in `sounds/`
- `tools/make-images.js`: makes the home-screen tile and the splash picture (`node tools/make-images.js`)
- `tools/make-sounds.js`: makes the burst of static heard when a channel opens (`node tools/make-sounds.js`)
- `tools/font-family-names.js`: the one change made to the Barlow Condensed files (see License)
- `tools/check.sh` and `.github/workflows/check.yml`: the check every push to main gets (the app compiles, every commit carries the project's name, nothing private slipped in)

## License

The code is under the MIT License with the Commons Clause: you can use and change it, but not sell it. See [LICENSE](LICENSE).

Rukus and the rest of the art, sound and writing are all rights reserved. See [LICENSE-ASSETS](LICENSE-ASSETS).

The fonts in `app/fonts` are Barlow Condensed, VT323, Silkscreen and W95FA, free fonts under the SIL Open Font License 1.1. Each folder holds the font's license and copyright in `OFL.txt`, except W95FA, whose license file came with no copyright filled in: its `README.txt` names the maker. Neither notice above covers the fonts. The Medium, SemiBold and ExtraBold files of Barlow Condensed have one change: their shared family name is taken out, so a Roku keeps each weight apart (`tools/font-family-names.js` makes that change).
