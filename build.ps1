$env:NODE_HOME = "D:\Program Files\Huawei\DevEco Studio\tools\node"
$env:DEVECO_SDK_HOME = "D:\Program Files\Huawei\DevEco Studio\sdk"
$env:JAVA_HOME = "D:\Program Files\Huawei\DevEco Studio\jbr"
$env:PATH = "$env:NODE_HOME;$env:JAVA_HOME\bin;" + $env:PATH

$log = "C:\Users\52622\AppData\Local\Temp\opencode\build_out.log"
$output = & "$env:NODE_HOME\node.exe" "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p product=default -p module=entry assembleHap --no-daemon 2>&1
$output -replace '\x1b\[[0-9;]*m','' | Set-Content $log -Encoding UTF8
$errors = $output | Where-Object { $_ -match "ERROR" }
$errors -replace '\x1b\[[0-9;]*m','' | ForEach-Object { "ERROR: " + $_ }
"===== SUMMARY ====="
if ($LASTEXITCODE -eq 0) { "BUILD SUCCESSFUL" } else { "BUILD FAILED (see $log)" }
exit $LASTEXITCODE
