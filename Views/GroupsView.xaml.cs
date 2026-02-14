using CommunityToolkit.Maui.Behaviors;

namespace WonderWall.Views;

public partial class GroupsView : ContentView
{
    public GroupsView(GroupsViewModel viewModel)
	{
		InitializeComponent();
		BindingContext = viewModel;
    }
}