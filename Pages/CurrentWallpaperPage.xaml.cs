using WonderWall.Views;

namespace WonderWall.Pages;

public partial class CurrentWallpaperPage : ContentPage
{
	public CurrentWallpaperPage(CurrentWallpaperView view)
	{
		InitializeComponent();
        contentView.Content = view;
    }
}