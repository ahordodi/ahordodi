# Configura automaticamente Claude Desktop para usar el conector de WhatsApp.
# Uso: parado en esta carpeta (whatsapp-connector), correr:
#   powershell -ExecutionPolicy Bypass -File .\setup-claude-desktop.ps1

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$mcpServerDir = Join-Path $projectRoot "whatsapp-mcp-server"

if (-not (Test-Path $mcpServerDir)) {
    Write-Host "No encuentro la carpeta whatsapp-mcp-server junto a este script ($mcpServerDir)." -ForegroundColor Red
    Write-Host "Corre este script desde adentro de la carpeta whatsapp-connector." -ForegroundColor Red
    exit 1
}

$uvCmd = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uvCmd) {
    $fallback = Join-Path $env:USERPROFILE ".local\bin\uv.exe"
    if (Test-Path $fallback) {
        $uvPath = $fallback
    } else {
        Write-Host "No encuentro 'uv' instalado. Instalalo primero con:" -ForegroundColor Red
        Write-Host '  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"'
        exit 1
    }
} else {
    $uvPath = $uvCmd.Source
}

# Si Claude Desktop se instalo como app empaquetada (MSIX/Store), Windows
# redirige %APPDATA%\Claude a una carpeta dentro de AppData\Local\Packages.
# Si existe esa carpeta, es la que la app realmente usa.
$packagedDir = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Claude_*" -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName "LocalCache\Roaming\Claude" } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if ($packagedDir) {
    $claudeDir = $packagedDir
} else {
    $claudeDir = Join-Path $env:APPDATA "Claude"
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }
}
$configPath = Join-Path $claudeDir "claude_desktop_config.json"

# Se usa PSCustomObject (no -AsHashtable) para que funcione igual en
# Windows PowerShell 5.1 y en PowerShell 7+.
if (Test-Path $configPath) {
    $raw = Get-Content $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $config = New-Object PSObject
    } else {
        $config = $raw | ConvertFrom-Json
    }
} else {
    $config = New-Object PSObject
}

if (-not (Get-Member -InputObject $config -Name "mcpServers" -MemberType NoteProperty)) {
    $config | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue (New-Object PSObject)
}

$whatsappEntry = [PSCustomObject]@{
    command = $uvPath
    args    = @("--directory", $mcpServerDir, "run", "main.py")
}

if (Get-Member -InputObject $config.mcpServers -Name "whatsapp" -MemberType NoteProperty) {
    $config.mcpServers.whatsapp = $whatsappEntry
} else {
    $config.mcpServers | Add-Member -NotePropertyName "whatsapp" -NotePropertyValue $whatsappEntry
}

$json = $config | ConvertTo-Json -Depth 10
Set-Content -Path $configPath -Value $json -Encoding UTF8

Write-Host "Listo. Configuracion escrita en:" -ForegroundColor Green
Write-Host "  $configPath"
Write-Host ""
Write-Host "uv:                 $uvPath"
Write-Host "whatsapp-mcp-server: $mcpServerDir"
Write-Host ""
Write-Host "Ahora cerra Claude Desktop del todo (icono en la bandeja del sistema -> Salir) y volvelo a abrir." -ForegroundColor Yellow
