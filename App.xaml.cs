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
    }
}