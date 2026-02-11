using Microsoft.Extensions.Logging;

namespace WonderWall;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        MauiAppBuilder builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });

        IServiceCollection services = builder.Services;
        services.AddDbContext<DbContext>();

#if WINDOWS
        services.AddSingleton<ITrayService, WinUI.TrayService>();
#endif


#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}