using Microsoft.EntityFrameworkCore;
using System.Data.Common;
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

    public string GetDbGenScript()
    {
        return Database.GenerateCreateScript().Trim();
    }

    public bool TableExists(string table)
    {
        using var command = Database.GetDbConnection().CreateCommand();
        command.CommandText = $"SELECT name from sqlite_master WHERE type='table' and name='{table}'";
        Database.OpenConnection();
        using var result = command.ExecuteReader();
        return result.Read();
    }

    public bool ColumnExists(string table, string column)
    {
        using var command = Database.GetDbConnection().CreateCommand();
        command.CommandText = $"pragma table_info('{table}')";
        Database.OpenConnection();
        using var result = command.ExecuteReader();
        while (result.Read())
        {
            if (result.GetString(1) == column)
            {
                return true;
            }
        }
        return false;
    }

    public bool ConstraintExists(string table, string constraint)
    {
        bool resultBool;

        using (DbCommand command = Database.GetDbConnection().CreateCommand())
        {
            command.CommandText = $"SELECT sql from sqlite_master WHERE type='table' and name='{table}'";
            Database.OpenConnection();
            using DbDataReader result = command.ExecuteReader();
            if (result.Read())
            {
                string lstr_sql = result[0]?.ToString() ?? "";
                resultBool = lstr_sql.Contains(constraint);
            }
            else
            {
                resultBool = false;
            }
        }

        return resultBool;
    }

}