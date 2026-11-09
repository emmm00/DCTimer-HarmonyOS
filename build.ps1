# 构建脚本：自动探测 DevEco Studio 安装位置，无需手改路径
# 用法：powershell -ExecutionPolicy Bypass -File .\build.ps1 [-Mode module|project] [-Task assembleHap|assembleApp]

param(
    [string]$Mode = 'module',
    [string]$Task = 'assembleHap'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# ---- 探测 DevEco Studio ----
$candidates = @(
    $env:DEVECO_STUDIO_HOME,
    'D:\Program Files\Huawei\DevEco Studio',
    'C:\Program Files\Huawei\DevEco Studio'
) | Where-Object { $_ -and (Test-Path (Join-Path $_ 'tools\hvigor\bin\hvigorw.js')) }

if (-not $candidates) {
    Write-Error "未找到 DevEco Studio。请设置 DEVECO_STUDIO_HOME 环境变量指向安装目录。"
    exit 1
}
$deveco = $candidates[0]
Write-Host "DevEco Studio: $deveco"

# ---- 环境变量 ----
$nodeHome = Join-Path $deveco 'tools\node'
$jbrHome = Join-Path $deveco 'jbr'
if (-not (Test-Path (Join-Path $nodeHome 'node.exe'))) {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCmd) { Write-Error "找不到 node.exe，且 DevEco 自带 node 不存在。"; exit 1 }
    $nodeExe = $nodeCmd.Source
} else {
    $nodeExe = Join-Path $nodeHome 'node.exe'
}

$env:NODE_HOME = $nodeHome
$env:DEVECO_SDK_HOME = Join-Path $deveco 'sdk'
$env:JAVA_HOME = $jbrHome
$env:PATH = "$($jbrHome)\bin;" + $env:PATH

# ---- 构建 ----
$hvigorJs = Join-Path $deveco 'tools\hvigor\bin\hvigorw.js'
$args = @('--mode', $Mode, '-p', 'product=default')
if ($Mode -eq 'module') { $args += @('-p', 'module=entry') }
$args += @($Task, '--no-daemon')

Write-Host "执行: node hvigorw.js $($args -join ' ')"
$output = & $nodeExe $hvigorJs @args 2>&1
$clean = $output -replace '\x1b\[[0-9;]*m', ''
$clean | ForEach-Object { Write-Host $_ }

Write-Host "===== SUMMARY ====="
# hvigor 退出码常为 1（deprecated 警告走 stderr），以日志内容为准
if ($clean -match 'BUILD SUCCESSFUL') {
    Write-Host "BUILD SUCCESSFUL"
    exit 0
} else {
    Write-Host "BUILD FAILED"
    exit 1
}
