$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Save-TerminalCapture {
    param(
        [string]$Path,
        [string]$Title,
        [string[]]$Lines
    )

    $width = 1600
    $lineHeight = 28
    $height = 96 + ($Lines.Count * $lineHeight)
    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $background = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(20, 24, 31))
    $header = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 42, 52))
    $text = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 235, 240))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(130, 205, 160))
    $font = [System.Drawing.Font]::new('Consolas', 15)
    $titleFont = [System.Drawing.Font]::new('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)

    $graphics.FillRectangle($background, 0, 0, $width, $height)
    $graphics.FillRectangle($header, 0, 0, $width, 52)
    $graphics.DrawString('Kubernetes Deployment Evidence', $titleFont, $text, 24, 15)
    $graphics.DrawString($Title, $titleFont, $muted, 1320, 15)

    $y = 72
    foreach ($line in $Lines) {
        $graphics.DrawString($line, $font, $text, 24, $y)
        $y += $lineHeight
    }

    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $titleFont.Dispose()
    $font.Dispose()
    $muted.Dispose()
    $text.Dispose()
    $header.Dispose()
    $background.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Invoke-CapturedCommand {
    param([string[]]$Arguments)

    $output = (& kubectl @Arguments 2>&1 | Out-String).TrimEnd()
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl $($Arguments -join ' ') failed: $output"
    }
    return $output
}

$screenshotDirectory = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Path $screenshotDirectory -Force | Out-Null

$podCommand = 'kubectl get pods -o wide'
$podOutput = Invoke-CapturedCommand -Arguments @('get', 'pods', '-o', 'wide')
$podLines = @("PS> $podCommand") + @($podOutput -split "`r?`n")
Save-TerminalCapture -Path (Join-Path $screenshotDirectory 'pods.png') -Title 'Pods' -Lines $podLines

$portTest = [System.Net.Sockets.TcpClient]::new()
try {
    $portTest.Connect('127.0.0.1', 3003)
} catch {
    throw 'Gateway port-forward is not listening on 127.0.0.1:3003. Start kubectl port-forward service/gateway-service 3003:3003 in another terminal, then rerun this script.'
} finally {
    $portTest.Dispose()
}

$testLines = @('PS> kubectl port-forward service/gateway-service 3003:3003')
$testLines += 'Forwarding from 127.0.0.1:3003 -> 3003'
$testLines += 'PS> curl.exe -fsS http://127.0.0.1:3003/health'
$testLines += (& curl.exe -fsS 'http://127.0.0.1:3003/health' 2>&1 | Out-String).TrimEnd()
if ($LASTEXITCODE -ne 0) { throw 'Gateway health request failed.' }

foreach ($route in @('api/users', 'api/products', 'api/orders')) {
    $testLines += "PS> curl.exe -fsS http://127.0.0.1:3003/$route"
    $testLines += (& curl.exe -fsS "http://127.0.0.1:3003/$route" 2>&1 | Out-String).TrimEnd()
    if ($LASTEXITCODE -ne 0) { throw "Gateway request to /$route failed." }
}

Save-TerminalCapture -Path (Join-Path $screenshotDirectory 'service-test.png') -Title 'Port Forward Tests' -Lines $testLines

$logCommand = 'kubectl logs deployment/gateway-service --tail=20'
$logOutput = Invoke-CapturedCommand -Arguments @('logs', 'deployment/gateway-service', '--tail=20')
$logLines = @("PS> $logCommand") + @($logOutput -split "`r?`n")
Save-TerminalCapture -Path (Join-Path $screenshotDirectory 'logs.png') -Title 'Gateway Logs' -Lines $logLines

Write-Output "Evidence images written to $screenshotDirectory"