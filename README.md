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

0.15 is a test build. Every app on your TV gets a channel in the late-night cable guide, now in its own fonts, and the guide remembers the channel you opened last. The options key (✱) opens a test page that shows what your TV allows, and Play switches between drawing at 1280 x 720 and at 1920 x 1080, to see which is sharper. The settings, the other looks and the games come next.

Roku TVs don't let an app switch the TV's inputs, so b0r3d TV leaves HDMI and the antenna to Roku's own home screen. And when you leave an app you opened from b0r3d TV, the TV goes to Roku's home screen, not back to b0r3d TV. To come back quickly, move b0r3d TV to the first spot on the home screen: highlight it there, press ✱ and move it.

## The remote

- **Up and down:** move through the channels
- **Rewind and fast-forward:** a page at a time
- **OK:** open the channel
- **Replay:** jump back to the channel you opened before, like a cable remote's LAST key
- **✱:** the test page
- **Back:** leave b0r3d TV

## Trying it

b0r3d TV installs through Roku's developer mode, which lets a TV hold one app you add yourself. It won't be in Roku's store.

1. Turn on developer mode on your Roku TV (Roku's developer documentation shows how).
2. Zip everything inside the `app` folder, so `manifest` sits at the top of the zip.
3. In a browser, open your TV's address (for example `http://192.168.1.20`), sign in as `rokudev` with the password you chose, and install the zip.

## What's here

- `app/`: the Roku app: `manifest`, the BrightScript code in `source/`, the pictures in `images/` and the fonts in `fonts/`
- `tools/make-images.js`: makes the home-screen tile and the splash picture (`node tools/make-images.js`)
- `tools/font-family-names.js`: the one change made to the Barlow Condensed files (see License)
- `tools/check.sh` and `.github/workflows/check.yml`: the check every push to main gets (the app compiles, every commit carries the project's name, nothing private slipped in)

## License

The code is under the MIT License with the Commons Clause: you can use and change it, but not sell it. See [LICENSE](LICENSE).

Rukus and the rest of the art, sound and writing are all rights reserved. See [LICENSE-ASSETS](LICENSE-ASSETS).

The fonts in `app/fonts` are Barlow Condensed and VT323, free fonts under the SIL Open Font License 1.1. Each folder holds the font's license and copyright in `OFL.txt`; neither notice above covers them. The Medium, SemiBold and ExtraBold files of Barlow Condensed have one change: their shared family name is taken out, so a Roku keeps each weight apart (`tools/font-family-names.js` makes that change).
