
namespace WonderWall;

public static class WindowExtensions
{
    private static IntPtr _Hwnd;
    public static IntPtr Hwnd
    {
        get
        {
            if (_Hwnd == IntPtr.Zero)
            {
                var window = Microsoft.Maui.Controls.Application.Current!.Windows[0].Handler.PlatformView as Microsoft.UI.Xaml.Window;
                _Hwnd = WinRT.Interop.WindowNative.GetWindowHandle(window);
            }
            return _Hwnd;
        }
    }

    public static void SetIcon(string iconFilename)
    {
        if (Hwnd == IntPtr.Zero)
            return;

        var hIcon = PInvoke.User32.LoadImage(IntPtr.Zero, iconFilename,
           PInvoke.User32.ImageType.IMAGE_ICON, 16, 16, PInvoke.User32.LoadImageFlags.LR_LOADFROMFILE);

        PInvoke.User32.SendMessage(Hwnd, PInvoke.User32.WindowMessage.WM_SETICON, (IntPtr)0, hIcon);
    }

    public static void BringToFront()
    {
        PInvoke.User32.ShowWindow(Hwnd, PInvoke.User32.WindowShowStyle.SW_SHOW);
        PInvoke.User32.ShowWindow(Hwnd, PInvoke.User32.WindowShowStyle.SW_RESTORE);

        _ = PInvoke.User32.SetForegroundWindow(Hwnd);
    }

    public static void MinimizeToTray()
    {
        PInvoke.User32.ShowWindow(Hwnd, PInvoke.User32.WindowShowStyle.SW_MINIMIZE);
        PInvoke.User32.ShowWindow(Hwnd, PInvoke.User32.WindowShowStyle.SW_HIDE);
    }
}
