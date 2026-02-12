using Microsoft.EntityFrameworkCore;
using WonderWall.Data;

namespace WonderWall.Database;

public class DbContext : Microsoft.EntityFrameworkCore.DbContext
{
    public DbSet<Group> Groups { get; set; }
    public DbSet<SearchTerm> SearchTerms { get; set; }

    public DbContext()
    {
        SQLitePCL.Batteries_V2.Init();
        this.Database.EnsureCreated();
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        string dbPath = Path.Combine(FileSystem.AppDataDirectory, "wonderwall.db");
        optionsBuilder.UseSqlite($"Filename={dbPath}");
    }
}