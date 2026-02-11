using Microsoft.EntityFrameworkCore;

namespace WonderWall.Database;

public class DbContext : Microsoft.EntityFrameworkCore.DbContext
{
    //public DbSet<TodoItem> TodoItems { get; set; }

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