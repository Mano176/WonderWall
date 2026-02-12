using WonderWall.Views;

namespace WonderWall.Pages;

public partial class GroupsPage : ContentPage
{
	public GroupsPage(GroupsView view)
	{
		InitializeComponent();
		contentView.Content = view;
	}
}