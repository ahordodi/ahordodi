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

$claudeDir = Join-Path $env:APPDATA "Claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}
$configPath = Join-Path $claudeDir "claude_desktop_config.json"

if (Test-Path $configPath) {
    $raw = Get-Content $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $config = [ordered]@{}
    } else {
        $config = $raw | ConvertFrom-Json -AsHashtable
    }
} else {
    $config = [ordered]@{}
}

if (-not $config.ContainsKey("mcpServers")) {
    $config["mcpServers"] = [ordered]@{}
}

$config["mcpServers"]["whatsapp"] = [ordered]@{
    command = $uvPath
    args    = @("--directory", $mcpServerDir, "run", "main.py")
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
