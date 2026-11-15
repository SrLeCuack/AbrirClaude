# AbrirClaude - build, sign and install / compilar, firmar e instalar
# Author / Autor: Sr.LeCuack
#
# EN: Run from an ADMIN PowerShell (needed to trust the self-signed certificate):
#       powershell -ExecutionPolicy Bypass -File .\build.ps1
#     Use -NoInstall to only build build\AbrirClaude.msix.
# ES: Ejecuta desde PowerShell como ADMINISTRADOR (para confiar en el certificado):
#       powershell -ExecutionPolicy Bypass -File .\build.ps1
#     Usa -NoInstall para solo generar build\AbrirClaude.msix.
param([switch]$NoInstall)
$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$build   = Join-Path $root 'build'
$layout  = Join-Path $build 'layout'
$msix    = Join-Path $build 'AbrirClaude.msix'
$subject = 'CN=AbrirClaude'   # must match Publisher in AppxManifest.xml / debe coincidir con el manifiesto

function Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }

# 1. SDK tools (makeappx + signtool): Windows SDK if installed, otherwise NuGet package
#    Herramientas del SDK: Windows SDK si está instalado, si no el paquete NuGet
Step 'Locating makeappx/signtool | Buscando makeappx/signtool'
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } elseif ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
function Find-Tool($name, $base) {
    if (-not (Test-Path $base)) { return $null }
    $all = Get-ChildItem $base -Recurse -Filter $name -ErrorAction SilentlyContinue | Sort-Object FullName -Descending
    ($all | Where-Object { $_.Directory.Name -eq $arch } | Select-Object -First 1),
    ($all | Where-Object { $_.Directory.Name -eq 'x64' } | Select-Object -First 1) |
        Where-Object { $_ } | Select-Object -First 1 -ExpandProperty FullName
}
$kits  = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
$tools = Join-Path $root 'tools'
$makeappx = Find-Tool 'makeappx.exe' $kits; $signtool = Find-Tool 'signtool.exe' $kits
if (-not $makeappx -or -not $signtool) {
    $makeappx = Find-Tool 'makeappx.exe' $tools; $signtool = Find-Tool 'signtool.exe' $tools
}
if (-not $makeappx -or -not $signtool) {
    Step 'Downloading Microsoft.Windows.SDK.BuildTools from nuget.org | Descargando de nuget.org'
    New-Item -ItemType Directory -Force $tools | Out-Null
    $zip = Join-Path $tools 'buildtools.zip'
    Invoke-WebRequest 'https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.BuildTools' -OutFile $zip -UseBasicParsing
    Expand-Archive $zip (Join-Path $tools 'sdk') -Force
    Remove-Item $zip
    $makeappx = Find-Tool 'makeappx.exe' $tools; $signtool = Find-Tool 'signtool.exe' $tools
}
if (-not $makeappx -or -not $signtool) { throw 'makeappx/signtool not found | no encontrados' }

# 2. Compile / Compilar (.NET Framework csc, included with Windows)
Step 'Compiling | Compilando'
$csc = Get-ChildItem "$env:WINDIR\Microsoft.NET\Framework64\v4*\csc.exe", "$env:WINDIR\Microsoft.NET\Framework\v4*\csc.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if (-not $csc) { throw 'csc.exe (.NET Framework 4) not found | no encontrado' }
if (Test-Path $layout) { Remove-Item $layout -Recurse -Force }
New-Item -ItemType Directory -Force $layout | Out-Null
& $csc /nologo /target:winexe /platform:anycpu "/out:$layout\AbrirClaude.exe" (Join-Path $root 'src\AbrirClaude.cs')
if ($LASTEXITCODE) { throw 'Compile failed | Falló la compilación' }

# 3. Package layout + pack / Armar y empaquetar
Step 'Packing MSIX | Empaquetando MSIX'
Copy-Item (Join-Path $root 'package\*') $layout -Recurse -Force
& $makeappx pack /o /d $layout /p $msix | Out-Null
if ($LASTEXITCODE) { throw 'makeappx failed | falló makeappx' }

# 4. Self-signed certificate (created once, reused) / Certificado autofirmado (se crea una vez)
Step 'Signing | Firmando'
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $subject -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } | Select-Object -First 1
if (-not $cert) {
    $cert = New-SelfSignedCertificate -Type Custom -Subject $subject -KeyUsage DigitalSignature `
        -FriendlyName 'AbrirClaude (self-signed)' -CertStoreLocation Cert:\CurrentUser\My `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
}
& $signtool sign /q /fd SHA256 /sha1 $cert.Thumbprint $msix
if ($LASTEXITCODE) { throw 'signtool failed | falló signtool' }
Write-Host "OK: $msix" -ForegroundColor Green
if ($NoInstall) { return }

# 5. Trust cert + install / Confiar en el certificado e instalar
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Run as Administrator to install | Ejecuta como Administrador para instalar' }
Step 'Trusting certificate | Confiando en el certificado (LocalMachine\TrustedPeople)'
$cer = Join-Path $build 'AbrirClaude.cer'
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null

Step 'Installing | Instalando'
Get-AppxPackage AbrirClaude.TeclaCopilot | Remove-AppxPackage
Add-AppxPackage $msix
Write-Host 'Done. Settings > Personalization > Text input > Copilot key > "Claude (consulta rapida)"' -ForegroundColor Green
Write-Host 'Listo. Configuración > Personalización > Entrada de texto > Tecla Copilot > "Claude (consulta rapida)"' -ForegroundColor Green
