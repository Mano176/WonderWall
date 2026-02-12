using CommunityToolkit.Maui;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.Maui.Controls.Shapes;
using System.Collections.ObjectModel;

namespace WonderWall.ViewModels;

public partial class GroupsViewModel : ObservableObject
{
    private readonly IPopupService popupService;
    private readonly DbContext dbContext;

    private GroupViewModel? selectedGroup;

    [ObservableProperty]
    private ObservableCollection<GroupViewModel> groups;

    public GroupsViewModel(DbContext dbContext, IPopupService popupService)
    {
        this.popupService = popupService;
        this.dbContext = dbContext;
        groups = new ObservableCollection<GroupViewModel>(LoadGroups());
    }

    public IEnumerable<GroupViewModel> LoadGroups()
    {
        return dbContext.Groups.Select(g => new GroupViewModel(g));
    }

    [RelayCommand]
    private void SelectGroup(GroupViewModel group)
    {
        if (selectedGroup != null)
        {
            selectedGroup.IsOpen = false;

            if (selectedGroup == group)
            {
                selectedGroup = null;
                return;
            }
        }

        group.IsOpen = true;
        selectedGroup = group;
    }

    [RelayCommand]
    private async Task AddGroup()
    {
        IPopupResult<string?> popupResult = await popupService.ShowPopupAsync<EditStringPopup, string?>(Shell.Current, options: null, new Dictionary<string, object>
        {
            { nameof(EditStringPopupViewModel.Title), "Group title" }
        });

        if (popupResult == null)
        {
            return;
        }

        Group group = new Group
        {
            Title = popupResult.Result!
        };

        dbContext.Groups.Add(group);
        dbContext.SaveChanges();

        groups.Add(new GroupViewModel(group));
    }

    [RelayCommand]
    private async Task AddSearchTerm(GroupViewModel group)
    {
        IPopupResult<string?> popupResult = await popupService.ShowPopupAsync<EditStringPopup, string?>(Shell.Current, options: null, new Dictionary<string, object>
        {
            { nameof(EditStringPopupViewModel.Title), "Search Term" }
        });

        if (popupResult == null)
        {
            return;
        }

        SearchTerm searchTerm = new SearchTerm
        {
            Title = popupResult.Result!,
            GroupId = group.Id
        };

        dbContext.SearchTerms.Add(searchTerm);
        dbContext.SaveChanges();

        group.SearchTerms.Add(new SearchTermViewModel(searchTerm));
    }
}