using CommunityToolkit.Mvvm.ComponentModel;

namespace WonderWall.ViewModels;

public class SearchTermViewModel : ObservableObject
{
    public readonly SearchTerm searchTerm;

    public SearchTermViewModel(SearchTerm searchterm)
    {
        this.searchTerm = searchterm;
    }

    public string Title
    {
        get => searchTerm.Title;
        set
        {
            if (searchTerm.Title != value)
            {
                searchTerm.Title = value;
                OnPropertyChanged(nameof(Title));
            }
        }
    }

    public bool IsEnabled
    {
        get => searchTerm.IsEnabled;
        set
        {
            if (searchTerm.IsEnabled != value)
            {
                searchTerm.IsEnabled = value;
                OnPropertyChanged();
            }
        }
    }
}
