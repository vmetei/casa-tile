# serve.ps1 - Tiny static file server for local preview
param(
  [int]$Port = 8080,
  [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Web
$prefix = "http://localhost:$Port/"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $Root at $prefix (Ctrl+C to stop)" -ForegroundColor Green

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.js'   = 'application/javascript; charset=utf-8'
  '.svg'  = 'image/svg+xml'
  '.json' = 'application/json'
  '.xml'  = 'application/xml; charset=utf-8'
  '.txt'  = 'text/plain; charset=utf-8'
  '.ico'  = 'image/x-icon'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.woff2' = 'font/woff2'
}

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $resp = $ctx.Response
    try {
      $rel = [System.Web.HttpUtility]::UrlDecode($req.Url.AbsolutePath)
      if ($rel -eq '/') { $rel = '/index.html' }
      if ($rel.EndsWith('/')) { $rel = "$rel" + 'index.html' }
      $path = Join-Path $Root ($rel.TrimStart('/').Replace('/', '\'))

      if (-not (Test-Path $path -PathType Leaf)) {
        $resp.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rel")
        $resp.OutputStream.Write($msg, 0, $msg.Length)
      } else {
        $ext = [System.IO.Path]::GetExtension($path).ToLower()
        $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $resp.ContentType = $type
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      Write-Host ("{0} {1} {2}" -f $resp.StatusCode, $req.HttpMethod, $rel)
    } catch {
      $logMsg = "Error: $($_.Exception.Message) | Path: $path"
      Write-Host $logMsg -ForegroundColor Red
      Add-Content -Path "$Root\serve.log" -Value $logMsg
    } finally {
      $resp.Close()
    }
  }
} finally {
  $listener.Stop()
}
