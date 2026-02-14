using CommunityToolkit.Maui.Views;

namespace WonderWall.Popups;

public partial class QuestionPopup : Popup<bool>
{
    public QuestionPopup(QuestionPopupViewModel viewmodel)
    {
        InitializeComponent();
        BindingContext = viewmodel;
    }
}