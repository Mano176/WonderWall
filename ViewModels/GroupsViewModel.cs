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
    private void ToggleGroup(GroupViewModel group)
    {
        dbContext.Groups.Attach(group.group);
        group.IsEnabled = !group.IsEnabled;
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private void ToggleSearchTerm(SearchTermViewModel searchTerm)
    {
        dbContext.SearchTerms.Attach(searchTerm.searchTerm);
        searchTerm.IsEnabled = !searchTerm.IsEnabled;
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private async Task AddGroup()
    {
        IPopupResult<string?> popupResult = await popupService.ShowPopupAsync<EditStringPopup, string?>(Shell.Current, options: null, new Dictionary<string, object>
        {
            { nameof(EditStringPopupViewModel.Title), "Group title" }
        });

        if (popupResult.Result == null)
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

        if (popupResult.Result == null)
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

    [RelayCommand]
    private async Task EditGroup(GroupViewModel group)
    {
        IPopupResult<string?> popupResult = await popupService.ShowPopupAsync<EditStringPopup, string?>(Shell.Current, shellParameters: new Dictionary<string, object>
        {
            { nameof(EditStringPopupViewModel.Title), "Group title" },
            { nameof(EditStringPopupViewModel.Value), group.Title }
        });

        if (popupResult.Result == null)
        {
            return;
        }

        dbContext.Groups.Attach(group.group);
        group.Title = popupResult.Result!;
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private async Task EditSearchTerm(SearchTermViewModel searchTerm)
    {
        IPopupResult<string?> popupResult = await popupService.ShowPopupAsync<EditStringPopup, string?>(Shell.Current, shellParameters: new Dictionary<string, object>
        {
            { nameof(EditStringPopupViewModel.Title), "Search Term" },
            { nameof(EditStringPopupViewModel.Value), searchTerm.Title }
        });

        if (popupResult.Result == null)
        {
            return;
        }

        dbContext.SearchTerms.Attach(searchTerm.searchTerm);
        searchTerm.Title = popupResult.Result!;
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private void PointerEnteredGroup(GroupViewModel group)
    {
        group.IsHovered = true;
    }

    [RelayCommand]
    private void PointerExitedGroup(GroupViewModel group)
    {
        group.IsHovered = false;
    }

    [RelayCommand]
    private void PointerEnteredSearchTerm(SearchTermViewModel searchTerm)
    {
        searchTerm.IsHovered = true;
    }

    [RelayCommand]
    private void PointerExitedSearchTerm(SearchTermViewModel searchTerm)
    {
        searchTerm.IsHovered = false;
    }

    [RelayCommand]
    private async Task DeleteGroup(GroupViewModel group)
    {
        IPopupResult<bool> popupResult = await popupService.ShowPopupAsync<QuestionPopup, bool>(Shell.Current, shellParameters: new Dictionary<string, object>
        {
            { nameof(QuestionPopupViewModel.Question), $"Do you really want to delete the group \"{group.Title}\"?" }
        });

        if (!popupResult.Result)
        {
            return;
        }

        groups.Remove(group);

        dbContext.SearchTerms.RemoveRange(dbContext.SearchTerms.Where(searchTerm => searchTerm.GroupId == group.group.Id));
        dbContext.Groups.Remove(group.group);
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private async Task DeleteSearchTerm(object[] parameters)
    {
        GroupViewModel group = ((GroupViewModel)parameters[0]);
        SearchTermViewModel searchTerm = ((SearchTermViewModel)parameters[1]);

        IPopupResult<bool> popupResult = await popupService.ShowPopupAsync<QuestionPopup, bool>(Shell.Current, shellParameters: new Dictionary<string, object>
        {
            { nameof(QuestionPopupViewModel.Question), $"Do you really want to delete the search term \"{searchTerm.Title}\"?" }
        });

        if (!popupResult.Result)
        {
            return;
        }

        group.SearchTerms.Remove(searchTerm);

        dbContext.SearchTerms.Remove(searchTerm.searchTerm);
        dbContext.SaveChanges();
    }

    [RelayCommand]
    private async Task SetGroupAsWallpaper(GroupViewModel group)
    {

    }

    [RelayCommand]
    private async Task SetSearchTermAsWallpaper(SearchTermViewModel searchTerm)
    {

    }
}