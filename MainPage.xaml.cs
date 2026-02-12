
using WonderWall.Views;

namespace WonderWall;

public partial class MainPage : ContentPage
{
    public MainPage(GroupsView groupsView, CurrentWallpaperView currentWallpaperView, SettingsView settingsView)
    {
        InitializeComponent();
        groupsContentView.Content = groupsView;
        currentWallpaperContentView.Content = currentWallpaperView;
        settingsContentView.Content = settingsView;
    }
}