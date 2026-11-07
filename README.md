# b0r3d TV

A home screen for Roku TVs that looks like an old cable box, made by [b0r3d.org](https://b0r3d.org).

Your apps and a couple of b0r3d games each get a channel in a retro channel guide, and you flip through them with the Roku remote.

It comes in four looks:

- **Late-night cable guide:** a blue grid of channels with a preview window
- **b0r3d 95:** a desktop with a channel guide window
- **Phosphor terminal:** one glowing color on black, with scanlines
- **VCR menu:** an on-screen menu with a picture-in-picture box

And two games: a falling-block game and a brick breaker.

## Status

0.1 is a first test build: the home screen in the late-night cable guide look, with three channels (your PC on HDMI 1, antenna TV and YouTube). The other looks and the games come next.

## Trying it

b0r3d TV installs through Roku's developer mode, which lets a TV hold one app you add yourself. It won't be in Roku's store.

1. Turn on developer mode on your Roku TV (Roku's developer documentation shows how).
2. Zip everything inside the `app` folder, so `manifest` sits at the top of the zip.
3. In a browser, open your TV's address (for example `http://192.168.1.20`), sign in as `rokudev` with the password you chose, and install the zip.

## What's here

- `app/`: the Roku app: `manifest`, the BrightScript code in `source/`, the pictures in `images/`
- `tools/make-images.js`: makes the home-screen tile and the splash picture (`node tools/make-images.js`)

## License

The code is under the MIT License with the Commons Clause: you can use and change it, but not sell it. See [LICENSE](LICENSE).

Rukus and the rest of the art, sound and writing are all rights reserved. See [LICENSE-ASSETS](LICENSE-ASSETS).
