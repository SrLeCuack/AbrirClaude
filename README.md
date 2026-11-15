# AbrirClaude — Copilot key → Claude Quick Entry

**[English](#english) · [Español](#español)**

Author / Autor: **Sr.LeCuack**

---

## English

### What it does
Turns the **Copilot key** on your Windows keyboard into a shortcut for **Claude Quick Entry**: the small floating box from the Claude desktop app where you type a quick question without opening the full window.

Press the Copilot key → the Quick Entry box appears → ask → done.

### Why it works this way
- Windows lets you choose which app the Copilot key opens (**Settings → Personalization → Text input → Copilot key**), but it only lists **packaged apps (MSIX)** that declare the `com.microsoft.windows.copilotkeyprovider` extension. The Claude app doesn't declare it, so it doesn't appear in that list.
- This project is a small MSIX package that **does** declare that extension, so it shows up in the list as **"Claude (consulta rapida)"**.
- When Windows launches it, the program (`src/AbrirClaude.cs`):
  1. Checks that the Claude desktop app is running. If not, it opens it and waits a few seconds, because the global shortcut only works while Claude is running.
  2. Waits until you release the Copilot key. The Copilot key is really `Win+Shift+F23`, so this keeps those keys from mixing with the shortcut.
  3. Sends **`Ctrl+Alt+Space`**, Claude's default Quick Entry shortcut on Windows, which opens the floating box.

### Requirements
- Windows 11 with a Copilot key (works on ARM64 and x64).
- [Claude desktop app](https://claude.ai/download) installed, with Quick Entry on its default shortcut `Ctrl+Alt+Space`.
- .NET Framework 4.x (included with Windows).
- `makeappx` / `signtool` from the Windows SDK. If they are missing, `build.ps1` downloads the official `Microsoft.Windows.SDK.BuildTools` package from nuget.org into `tools/`.

### Install
1. Open **PowerShell as Administrator** in this folder.
2. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1
   ```
   The script:
   - compiles `src/AbrirClaude.cs`
   - builds `build/AbrirClaude.msix`
   - creates a self-signed certificate `CN=AbrirClaude` (only once) and signs the package
   - trusts that certificate in `LocalMachine\TrustedPeople` (this is why it needs admin)
   - installs the package, replacing any previous version
3. Go to **Settings → Personalization → Text input → Copilot key** and choose **"Claude (consulta rapida)"**.

To only build the `.msix` without installing it: `.\build.ps1 -NoInstall`

Admin is only needed the first time, to trust the certificate. After that, `build.ps1` installs updates without admin.

**Icon:** if the Claude app is installed, `build.ps1` copies the Claude logo from **your own installation** at build time, so the logo is not included in this repo. Use `.\build.ps1 -GenericIcons` to keep the generic "?" icon.

### Customize
- **Different shortcut:** if you changed Claude's Quick Entry shortcut, edit the `keybd_event` lines in `src/AbrirClaude.cs` and run `build.ps1` again.
- **Another assistant (ChatGPT, etc.):** change `ClaudeAumid`, `ClaudeExeMarker` and the keys that get sent (for example, ChatGPT uses `Alt+Space`).

### Uninstall
```powershell
Get-AppxPackage AbrirClaude.TeclaCopilot | Remove-AppxPackage
```
Optional: remove the `CN=AbrirClaude` certificate from `Cert:\LocalMachine\TrustedPeople` and `Cert:\CurrentUser\My`.

### Project structure
```
src/AbrirClaude.cs        Program: opens Claude if needed and sends Ctrl+Alt+Space
package/AppxManifest.xml  MSIX manifest with the Copilot key extension
package/Assets/           Generic icons
package/Public/           Public folder required by the extension
build.ps1                 Compile + package + sign + install
```

### Notes
- This is an unofficial personal project. It is not affiliated with Anthropic or Microsoft. "Claude" and "Copilot" are trademarks of their respective owners.
- License: MIT.

---

## Español

### Qué hace
Convierte la **tecla Copilot** de tu teclado en Windows en un atajo para la **consulta rápida de Claude (Quick Entry)**: el recuadro flotante de la app de escritorio de Claude donde escribes una pregunta rápida sin abrir la ventana completa.

Presionas la tecla Copilot → aparece el recuadro → preguntas → listo.

### Por qué funciona así
- Windows deja elegir qué app abre la tecla Copilot (**Configuración → Personalización → Entrada de texto → Tecla Copilot**), pero solo muestra **apps empaquetadas (MSIX)** que declaran la extensión `com.microsoft.windows.copilotkeyprovider`. La app de Claude no la declara, así que no sale en esa lista.
- Este proyecto es un paquete MSIX pequeño que **sí** declara esa extensión, así que aparece en la lista como **"Claude (consulta rapida)"**.
- Cuando Windows lo lanza, el programa (`src/AbrirClaude.cs`):
  1. Revisa que la app de escritorio de Claude esté abierta. Si no lo está, la abre y espera unos segundos, porque el atajo global solo funciona con Claude abierto.
  2. Espera a que sueltes la tecla Copilot. La tecla Copilot en realidad es `Win+Shift+F23`, así que esto evita que esas teclas se mezclen con el atajo.
  3. Envía **`Ctrl+Alt+Espacio`**, el atajo predeterminado de la consulta rápida de Claude en Windows, que abre el recuadro flotante.

### Requisitos
- Windows 11 con tecla Copilot (funciona en ARM64 y x64).
- [App de escritorio de Claude](https://claude.ai/download) instalada, con la consulta rápida en su atajo predeterminado `Ctrl+Alt+Espacio`.
- .NET Framework 4.x (viene con Windows).
- `makeappx` / `signtool` del Windows SDK. Si no los tienes, `build.ps1` descarga el paquete oficial `Microsoft.Windows.SDK.BuildTools` de nuget.org en `tools/`.

### Instalación
1. Abre **PowerShell como Administrador** en esta carpeta.
2. Ejecuta:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1
   ```
   El script:
   - compila `src/AbrirClaude.cs`
   - arma `build/AbrirClaude.msix`
   - crea un certificado autofirmado `CN=AbrirClaude` (solo la primera vez) y firma el paquete
   - confía en ese certificado en `LocalMachine\TrustedPeople` (por eso pide administrador)
   - instala el paquete y reemplaza la versión anterior si existe
3. Ve a **Configuración → Personalización → Entrada de texto → Tecla Copilot** y elige **"Claude (consulta rapida)"**.

Para solo generar el `.msix` sin instalarlo: `.\build.ps1 -NoInstall`

Solo se necesita administrador la primera vez, para confiar en el certificado. Después, `build.ps1` instala las actualizaciones sin administrador.

**Ícono:** si tienes la app de Claude instalada, `build.ps1` copia el logo de Claude desde **tu propia instalación** al compilar, así que el logo no viene en este repo. Usa `.\build.ps1 -GenericIcons` para dejar el ícono genérico "?".

### Personalizar
- **Otro atajo:** si cambiaste el atajo de la consulta rápida en Claude, edita las líneas `keybd_event` en `src/AbrirClaude.cs` y vuelve a correr `build.ps1`.
- **Otro asistente (ChatGPT, etc.):** cambia `ClaudeAumid`, `ClaudeExeMarker` y las teclas que se envían (por ejemplo, ChatGPT usa `Alt+Espacio`).

### Desinstalar
```powershell
Get-AppxPackage AbrirClaude.TeclaCopilot | Remove-AppxPackage
```
Opcional: borra el certificado `CN=AbrirClaude` de `Cert:\LocalMachine\TrustedPeople` y de `Cert:\CurrentUser\My`.

### Estructura
```
src/AbrirClaude.cs        Programa: abre Claude si hace falta y envía Ctrl+Alt+Espacio
package/AppxManifest.xml  Manifiesto MSIX con la extensión de la tecla Copilot
package/Assets/           Iconos genéricos
package/Public/           Carpeta pública que pide la extensión
build.ps1                 Compilar + empaquetar + firmar + instalar
```

### Notas
- Es un proyecto personal no oficial. No está afiliado a Anthropic ni a Microsoft. "Claude" y "Copilot" son marcas de sus respectivos dueños.
- Licencia: MIT.

---

Made by / Hecho por **Sr.LeCuack**
