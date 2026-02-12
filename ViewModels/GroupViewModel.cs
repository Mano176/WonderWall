using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;

namespace WonderWall.ViewModels;

public partial class GroupViewModel : ObservableObject
{
    private readonly Group group;

    public GroupViewModel(Group group)
    {
        this.group = group;
        SearchTerms = new ObservableCollection<SearchTermViewModel>(ServiceProvider.GetService<DbContext>().SearchTerms.Where(st => st.GroupId == group.Id).Select(st => new SearchTermViewModel(st)));
    }

    public int Id
    {
        get => group.Id;
    }

    public string Title
    {
        get => group.Title;
        set
        {
            if (group.Title != value)
            {
                group.Title = value;
                OnPropertyChanged(nameof(Title));
            }
        }
    }

    public ObservableCollection<SearchTermViewModel> SearchTerms { get; init; }

    [ObservableProperty]
    private bool isOpen;

    [ObservableProperty]
    private double iconRotation;

    partial void OnIsOpenChanged(bool value)
    {
        IconRotation = value ? 90 : 0;
    }
}
