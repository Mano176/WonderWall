using System.Diagnostics.CodeAnalysis;
using WonderWall.Platforms.Windows.NativeWindowing;
using Point = WonderWall.Platforms.Windows.NativeWindowing.Point;

namespace WonderWall.WinUI;

public class TrayService : ITrayService
{
    WindowsTrayIcon? tray;
    private bool _isCheckboxClicked = false;

    public Action? ClickHandler { get; set; }

    public void Initialize()
    {
        tray = new WindowsTrayIcon("Platforms/Windows/trayicon.ico");
        tray.LeftClick = () =>
        {
            WindowExtensions.BringToFront();
            ClickHandler?.Invoke();
        };

        tray.RightClick = () =>
        {
            ShowTrayContextMenu();
        };
    }

    private void ShowTrayContextMenu()
    {
        IntPtr hMenu = WinApi.CreatePopupMenu();

        const uint ID_OPEN = 2001;
        const uint ID_CHECKBOX = 2002;
        const uint ID_EXIT = 2003;

        WinApi.AppendMenu(hMenu, WinApi.MF_STRING, ID_OPEN, "App öffnen");

        uint checkboxFlags = WinApi.MF_STRING | (_isCheckboxClicked ? WinApi.MF_CHECKED : WinApi.MF_UNCHECKED);
        WinApi.AppendMenu(hMenu, checkboxFlags, ID_CHECKBOX, "Feature aktivieren");

        WinApi.AppendMenu(hMenu, 0x00000800, 0, string.Empty); // Trennlinie
        WinApi.AppendMenu(hMenu, WinApi.MF_STRING, ID_EXIT, "Beenden");

        // 3. Mausposition ermitteln
        Point mousePos = new Point();
        WinApi.GetCursorPos(ref mousePos);

        // 4. Fokus-Fix: Verhindert, dass das Menü offen bleibt, wenn man daneben klickt
        // Wir nutzen das Handle des versteckten Fensters aus dem TrayIcon
        nint trayHandle = tray!.GetHandle();
        WinApi.SetForegroundWindow(trayHandle);

        // 5. Menü anzeigen
        // TPM_RETURNCMD sorgt dafür, dass die Funktion die ID_OPEN oder ID_EXIT zurückgibt
        uint command = WinApi.TrackPopupMenu(
            hMenu,
            WinApi.TPM_RETURNCMD | WinApi.TPM_LEFTALIGN,
            mousePos.X,
            mousePos.Y - 15,
            0,
            trayHandle,
            IntPtr.Zero);

        // 6. Auswahl verarbeiten
        switch (command)
        {
            case ID_OPEN:
                WindowExtensions.BringToFront();
                ClickHandler?.Invoke();
                break;
            case ID_CHECKBOX:
                _isCheckboxClicked = !_isCheckboxClicked;
                Console.WriteLine($"Checkbox geklickt! Neuer Status: {_isCheckboxClicked}");
                break;
            case ID_EXIT:
                // Beendet die MAUI App sauber
                Application.Current?.Quit();
                break;
        }

        // 7. Ressourcen aufräumen
        WinApi.DestroyMenu(hMenu);
    }
}
