using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using DbContext = WonderWall.Database.DbContext;

namespace WonderWall;

public partial class App : Application
{
    private bool IsInitialized;

    public App()
    {
        InitializeComponent();
        CheckDbMigration();
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        Initialize();

        Window window = new Window(new AppShell());
        window.Title = "WonderWall";
        window.MinimumWidth = 1200;
        window.MinimumHeight = 900;

        return window;
    }

    private void Initialize()
    {
        if (IsInitialized)
            return;

        IsInitialized = true;
        InitializeTrayIcon();
    }

    private void InitializeTrayIcon()
    {
        ITrayService trayService = ServiceProvider.GetService<ITrayService>();

        if (trayService != null)
        {
            trayService.Initialize();
        }
    }

    private void CheckDbMigration()
    {
        string dbGenScriptPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DbGenScript.txt");

        string? dbGenScriptPrev = null;
        if (File.Exists(dbGenScriptPath))
        {
            dbGenScriptPrev = File.ReadAllText(dbGenScriptPath);
        }

        DbContext dbContext = ServiceProvider.GetService<DbContext>();
        string dbGenScript = dbContext.GetDbGenScript();
        File.WriteAllText(dbGenScriptPath, dbGenScript);

        if (dbGenScriptPrev == null)
        {
            return;
        }

        if (dbGenScriptPrev != dbGenScript)
        {
            MigrateDb(dbContext, dbGenScript);
        }
    }

    private void MigrateDb(DbContext dbContext, string dbGenScript)
    {
        List<string> keyDefinitions = [];

        foreach (string tableDefinition in dbGenScript!.Split(';'))
        {
            if (!tableDefinition.Contains("CREATE "))
                continue;

            string tableDef = MakeSqliteConform(tableDefinition[tableDefinition.IndexOf("CREATE ")..]) + ";";
            string type = tableDef.Substring(7, 5);
            string table = tableDef.Split(' ')[2];
            string[] fieldDefinitions = tableDef.Split('\n');

            switch (type)
            {
                case "TABLE":
                    if (!dbContext.TableExists(table))
                    {
                        _ = dbContext.Database.ExecuteSqlRaw(tableDef);
                    }
                    else
                    {
                        for (int i = 1; i < fieldDefinitions.Length - 1; i++)
                        {
                            string fieldDefinition = fieldDefinitions[i].Trim();
                            string[] fieldDefinitionParts = fieldDefinition.Split(' ');

                            if (fieldDefinition.EndsWith(','))
                            {
                                fieldDefinition = fieldDefinition[..^1];
                            }

                            if (fieldDefinitionParts[0] == "CONSTRAINT")
                            {
                                if (!dbContext.ConstraintExists(table, fieldDefinitionParts[1]))
                                {
                                    keyDefinitions.Add($"ALTER TABLE {table} ADD {fieldDefinition}");
                                }
                            }
                            else
                            {
                                if (!dbContext.ColumnExists(table, fieldDefinitionParts[0]))
                                {
                                    _ = dbContext.Database.ExecuteSqlRaw($"ALTER TABLE {table} ADD {fieldDefinition}");
                                }
                            }
                        }
                    }
                    break;

                case "INDEX":
                    keyDefinitions.Add(tableDef.Insert(13, "IF NOT EXISTS "));
                    break;
            }
        }

        foreach (string keyDefinition in keyDefinitions)
        {
            _ = dbContext.Database.ExecuteSqlRaw(keyDefinition);
        }
    }

    private string MakeSqliteConform(string sql)
    {
        return sql
            .Replace("\"", "")
            .Replace("INTEGER NOT NULL", "INTEGER NOT NULL DEFAULT '0'")
            .Replace("TEXT NOT NULL", "TEXT NOT NULL DEFAULT ''")
            .Replace("REAL NOT NULL", "REAL NOT NULL DEFAULT '0.0'");
    }
}