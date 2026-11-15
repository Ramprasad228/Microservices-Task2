$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$routes = @('api/users', 'api/products', 'api/orders', 'health')
$lines = @(
    'PS> kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80',
    'Forwarding from 127.0.0.1:8080 -> 80'
)

foreach ($route in $routes) {
    $url = "http://127.0.0.1:8080/$route"
    $lines += "PS> curl.exe -sS -o NUL -w `"HTTP %{http_code}`" -H `"Host: microservices.local`" $url"
    $result = (& curl.exe -sS -o NUL -w 'HTTP %{http_code}' -H 'Host: microservices.local' $url 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $result -notmatch 'HTTP 200') {
        throw "Ingress request failed for /$route ($result). Ensure the Ingress controller port-forward is active on 127.0.0.1:8080."
    }
    $lines += $result
}

$width = 1600
$lineHeight = 30
$height = 96 + ($lines.Count * $lineHeight)
$bitmap = [System.Drawing.Bitmap]::new($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$background = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(20, 24, 31))
$header = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 42, 52))
$text = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 235, 240))
$success = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(130, 205, 160))
$font = [System.Drawing.Font]::new('Consolas', 15)
$titleFont = [System.Drawing.Font]::new('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)

$graphics.FillRectangle($background, 0, 0, $width, $height)
$graphics.FillRectangle($header, 0, 0, $width, 52)
$graphics.DrawString('Kubernetes Ingress Evidence', $titleFont, $text, 24, 15)
$graphics.DrawString('HTTP 200', $titleFont, $success, 1440, 15)

$y = 72
foreach ($line in $lines) {
    $brush = if ($line -match '^HTTP 200$') { $success } else { $text }
    $graphics.DrawString($line, $font, $brush, 24, $y)
    $y += $lineHeight
}

$outputDirectory = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$bitmap.Save((Join-Path $outputDirectory 'ingress-test.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$titleFont.Dispose()
$font.Dispose()
$success.Dispose()
$text.Dispose()
$header.Dispose()
$background.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Output "Ingress evidence image written to $outputDirectory\ingress-test.png"