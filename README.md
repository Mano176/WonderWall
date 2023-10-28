# [WonderWall](https://github.com/Mano176/WonderWall)
[//]: <> (badges_start)
![GitHub release](https://img.shields.io/github/v/release/Mano176/WonderWall)
![GitHub top language](https://img.shields.io/github/languages/top/Mano176/WonderWall)
![repository size](https://img.shields.io/github/repo-size/Mano176/WonderWall)
![GitHub Repo stars](https://img.shields.io/github/stars/Mano176/WonderWall)

[//]: <> (badges_end)

[//]: <> (description_start)
A simple application for generating windows wallpapers, with the following features
- 🌄 Downloads beautiful high resolution images from [Unsplash.com](https://unsplash.com/)
- ⏬ Images are downloaded based off customizable search terms
- ✅ Search terms can be disabled and grouped for maximum flexibility
- 💨 Windows system tray integration to quickly change the wallpaper and open the settings
- 📅 Windows autostart support to change your wallpaper daily

[//]: <> (description_end)

[//]: <> (images_start)
<p align="center">
    <img src="screenshots/settings.png" alt="start screen" width="600"/><br>
    Settings
</p>

<p align="center">
    <img src="screenshots/systemtray.png" alt="start screen" width="300"/><br>
    System tray
</p>

[//]: <> (images_end)

[//]: <> (installation_start)
## Installation
To install your own version of Wonderwall follow these steps:
1. Download the newst version from [Releases](https://github.com/Mano176/WonderWall/releases)
2. Head to [Unsplash](https://unsplash.com/developers) and create your own Unsplash-App. Then copy your client id
3. Open the file `wonderwall/data/flutter_assets/assets/secrets.json`. The file looks like this:
    ```json
    {"clientId": "[your client id]"}
    ```
4. Replace `[your client id]` with your Unsplash client id and save the file
5. Run `wonderwall.exe`

[//]: <> (installation_end)