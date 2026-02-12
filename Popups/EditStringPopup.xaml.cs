using CommunityToolkit.Maui.Views;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace WonderWall.Popups;

public partial class EditStringPopup : Popup<string?>
{
	public EditStringPopup(EditStringPopupViewModel viewModel)
	{
		InitializeComponent();
		BindingContext = viewModel;
	}

    private void Popup_Opened(object sender, EventArgs e)
    {
		Entry.Focus();
    }
}