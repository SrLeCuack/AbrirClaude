// AbrirClaude - Copilot key -> Claude Quick Entry
// Author / Autor: Sr.LeCuack
//
// EN: Launched by Windows when the Copilot key is pressed. Makes sure the Claude
//     desktop app is running, then sends Claude's Quick Entry shortcut
//     (Ctrl+Alt+Space by default on Windows) to open the floating quick-question box.
// ES: Windows lo lanza al presionar la tecla Copilot. Se asegura de que la app de
//     escritorio de Claude esté abierta y luego envía el atajo de Consulta Rápida
//     (Ctrl+Alt+Espacio por defecto en Windows) para abrir el recuadro flotante.
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

static class AbrirClaude {
    const string ClaudeAumid = @"shell:AppsFolder\AnthropicPBC.Claude_fnn82j28hfe8t!Claude";
    const string ClaudeExeMarker = "AnthropicPBC.Claude";

    const byte VK_SHIFT = 0x10, VK_CONTROL = 0x11, VK_MENU = 0x12, VK_SPACE = 0x20;
    const byte VK_LWIN = 0x5B, VK_RWIN = 0x5C;
    const uint KEYEVENTF_KEYUP = 0x0002;

    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int vk);

    static void Main() {
        // EN: Start Claude if it is not running (the global shortcut only works while it runs).
        // ES: Abre Claude si no está corriendo (el atajo global solo funciona con la app abierta).
        if (!ClaudeRunning()) {
            var psi = new ProcessStartInfo("explorer.exe", ClaudeAumid);
            psi.UseShellExecute = false;
            Process.Start(psi);
            for (int i = 0; i < 40 && !ClaudeRunning(); i++) Thread.Sleep(250);
            Thread.Sleep(3000); // EN: let it register the shortcut / ES: tiempo para registrar el atajo
        }

        // EN: The Copilot key is Win+Shift+F23; wait until those keys are released
        //     so they don't mix with our shortcut.
        // ES: La tecla Copilot es Win+Shift+F23; esperamos a que se suelten para que
        //     no se mezclen con nuestro atajo.
        for (int i = 0; i < 40 && AnyModifierDown(); i++) Thread.Sleep(25);

        // Ctrl+Alt+Space
        keybd_event(VK_CONTROL, 0, 0, UIntPtr.Zero);
        keybd_event(VK_MENU, 0, 0, UIntPtr.Zero);
        keybd_event(VK_SPACE, 0, 0, UIntPtr.Zero);
        keybd_event(VK_SPACE, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }

    static bool ClaudeRunning() {
        foreach (var p in Process.GetProcessesByName("claude")) {
            try { if (p.MainModule.FileName.Contains(ClaudeExeMarker)) return true; }
            catch { }
        }
        return false;
    }

    static bool AnyModifierDown() {
        foreach (byte k in new byte[] { VK_LWIN, VK_RWIN, VK_SHIFT, VK_CONTROL, VK_MENU })
            if ((GetAsyncKeyState(k) & 0x8000) != 0) return true;
        return false;
    }
}
