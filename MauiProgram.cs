using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;
using Microsoft.Maui.Controls.Shapes;
using WonderWall.Pages;
using WonderWall.Views;


namespace WonderWall;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        MauiAppBuilder builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .UseMauiCommunityToolkit(options =>
            {
                options.SetPopupDefaults(new DefaultPopupSettings
                {
                    CanBeDismissedByTappingOutsideOfPopup = false
                });
                options.SetPopupOptionsDefaults(new DefaultPopupOptionsSettings
                {
                    Shape = new RoundRectangle
                    {
                        CornerRadius = new CornerRadius(10),
                        Stroke = Colors.White,
                        StrokeThickness = 1
                    }
                });
            })
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                fonts.AddFont("MaterialSymbolsRounded.ttf", "MaterialIcons");
            });

        IServiceCollection services = builder.Services;
        services.AddDbContext<DbContext>();

        // ViewModels
        services.AddSingleton<GroupsViewModel>();

        // Views
        services.AddSingleton<GroupsView>();
        services.AddSingleton<SettingsView>();
        services.AddSingleton<CurrentWallpaperView>();

        // Pages
        services.AddSingleton<MainPage>();
        services.AddSingleton<GroupsPage>();
        services.AddSingleton<SettingsPage>();
        services.AddSingleton<CurrentWallpaperPage>();

        // Popups
        services.AddTransientPopup<EditStringPopup, EditStringPopupViewModel>();


#if WINDOWS
        services.AddSingleton<ITrayService, WinUI.TrayService>();
#endif


#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}