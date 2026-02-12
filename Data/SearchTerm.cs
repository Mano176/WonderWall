
using System.ComponentModel.DataAnnotations;

namespace WonderWall.Data;

public class SearchTerm
{
    [Key]
    public int Id { get; set; }

    public int GroupId { get; set; }

    public required string Title { get; set; }
}
