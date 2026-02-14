using CommunityToolkit.Maui;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace WonderWall.ViewModels;

public partial class QuestionPopupViewModel(IPopupService popupService) : ObservableObject, IQueryAttributable
{
    [ObservableProperty]
    private string question = null!;

    [ObservableProperty]
    private string yesString = "Yes";

    [ObservableProperty]
    private string noString = "No";

    public void ApplyQueryAttributes(IDictionary<string, object> query)
    {
        Question = (string)query[nameof(Question)];

        if (query.TryGetValue(nameof(YesString), out object? yesObj) && yesObj is string yesString)
        {
            YesString = yesString;
        }

        if (query.TryGetValue(nameof(YesString), out object? noObj) && noObj is string noString)
        {
            NoString = noString;
        }
    }

    [RelayCommand]
    private async Task No()
    {
        await popupService.ClosePopupAsync<bool>(Shell.Current, false);
    }

    [RelayCommand]
    public async Task Yes()
    {
        await popupService.ClosePopupAsync<bool>(Shell.Current, true);
    }
}