using CommunityToolkit.Maui;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace WonderWall.ViewModels;

public partial class EditStringPopupViewModel(IPopupService popupService) : ObservableObject, IQueryAttributable
{
    [ObservableProperty]
    private string title = null!;

    [ObservableProperty]
    [NotifyCanExecuteChangedFor(nameof(SaveCommand))]
    private string value = "";

    public void ApplyQueryAttributes(IDictionary<string, object> query)
    {
        Title = (string)query[nameof(Title)];

        if (query.TryGetValue(nameof(Value), out object? valueObj) && valueObj is string valueString)
        {
            Value = valueString;
        }
    }

    private bool CanSave()
    {
        return !string.IsNullOrWhiteSpace(Value);
    }

    [RelayCommand(CanExecute = nameof(CanSave))]
    private async Task Save()
    {
        await popupService.ClosePopupAsync<string?>(Shell.Current, value);
    }

    [RelayCommand]
    public async Task Cancel()
    {
        await popupService.ClosePopupAsync<string?>(Shell.Current, null);
    }
}