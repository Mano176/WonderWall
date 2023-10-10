# WonderWall
![GitHub top language](https://img.shields.io/github/languages/top/Mano176/WonderWall)
![repository size](https://img.shields.io/github/repo-size/Mano176/WonderWall)
![GitHub Repo stars](https://img.shields.io/github/stars/Mano176/WonderWall)

A simple application for generating windows wallpapers, with following features:
- 🌄 Downloads beautiful high resolution images from [Unsplash.com](https://unsplash.com/)
- ⏬ Images are downloaded based off customizable search terms
- ✅ Search terms can be disabled and grouped for maximum flexibility
- 💨 Windows system tray integration to quickly change the wallpaper and open the settings
- 📅 Windows autostart support to change your wallpaper daily

<p align="center">
    <img src="screenshots/settings.png" alt="start screen" width="600"/><br>
    Settings
</p>

<p align="center">
    <img src="screenshots/systemtray.png" alt="start screen" width="300"/><br>
    System tray
</p>

## Installation

To install your own version of Wonderwall follow these 3 steps:
1. Clone the repository with `git clone https://github.com/Mano176/WonderWall`
2. Head to [Unsplash](https://unsplash.com/developers) and create your own Unsplash-App. Then copy your client id from Unsplash and create a `/assets/secret.json` file like this:
    ```json
    {"clientId": "your client id"}
    ```
3. Build your own version of Wonderwall with by executing the `build.bat` script. The output will be in `build_output/windows/release`