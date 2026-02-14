using CommunityToolkit.Mvvm.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace WonderWall.Data;

public class Group
{
    [Key]
    public int Id { get; set; }

    public required string Title { get; set; }

    public bool IsEnabled { get; set; } = true;
}
