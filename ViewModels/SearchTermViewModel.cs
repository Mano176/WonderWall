using CommunityToolkit.Mvvm.ComponentModel;

namespace WonderWall.ViewModels;

public class SearchTermViewModel : ObservableObject
{
    private readonly SearchTerm searchTerm;

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
}
