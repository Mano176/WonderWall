using Microsoft.Extensions.DependencyInjection;

namespace WonderWall
{
    public partial class App : Application
    {
        private bool IsInitialized;

        public App()
        {
            InitializeComponent();
        }

        protected override Window CreateWindow(IActivationState? activationState)
        {
            Initialize();

            Page page;
            if (DeviceInfo.Idiom == DeviceIdiom.Desktop)
            {
                page = new MainPage();
            }
            else
            {
                page = new AppShell();
            }

            Window window = new Window(page);
            window.Title = "WonderWall";

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
    }
}