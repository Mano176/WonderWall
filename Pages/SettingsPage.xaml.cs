using WonderWall.Views;

namespace WonderWall.Pages;

public partial class SettingsPage : ContentPage
{
	public SettingsPage(SettingsView view)
	{
		InitializeComponent();
        contentView.Content = view;
    }
}