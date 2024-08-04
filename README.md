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
    <img src="screenshots/settings.png" alt="settings screen" width="600"/><br>
    Settings
</p>

<p align="center">
    <img src="screenshots/systemtray.png" alt="system tray icon" width="300"/><br>
    System tray
</p>

[//]: <> (images_end)

[//]: <> (installation_start)
## Installation
To install your own version of Wonderwall follow these steps:
1. Download the newst version from [Releases](https://github.com/Mano176/WonderWall/releases)
2. Head to [Unsplash](https://unsplash.com/developers) and create your own Unsplash-App. Then copy your client id
3. Open the file `wonderwall/data/flutter_assets/assets/secrets.json` and replace `[your unplash client id]` with your Unsplash client id
4. Head to [Firebase](https://firebase.google.com/) and create a new project with `Authentication` and `Firestore Database` enabled
5. Under `Authentication >> Sign-in method` enable Google as provider and locate the Web client ID and the Web client secret
6. Again open `wonderwall/data/flutter_assets/assets/secrets.json` and replace `[your google client id]` with the Web client ID and replace `[your google client secret]` with the Web client secret
5. Run `wonderwall.exe`

[//]: <> (installation_end)