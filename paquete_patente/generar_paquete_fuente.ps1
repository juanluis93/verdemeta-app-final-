$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$root = Split-Path -Parent $PSScriptRoot
$fecha = Get-Date -Format "yyyyMMdd"
$dest = Join-Path $PSScriptRoot "VERDEMETA_CODIGO_FUENTE_$fecha.zip"
$hashFile = Join-Path $PSScriptRoot "VERDEMETA_CODIGO_FUENTE_$fecha.sha256.txt"

if (Test-Path $dest) {
    Remove-Item $dest -Force
}

$excludeDirPatterns = @(
    "flutter-migration/build/*",
    "flutter-migration/recovered_from_apk/*",
    "flutter-migration/.dart_tool/*",
    ".git/*",
    "paquete_patente/*"
)

$files = Get-ChildItem -Path $root -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($root.Length + 1).Replace('\\', '/')

    $isExcludedDir = $false
    foreach ($pattern in $excludeDirPatterns) {
        if ($rel -like $pattern) {
            $isExcludedDir = $true
            break
        }
    }

    $isGeneratedArtifact = $rel -match "/(generated|outputs|intermediates|tmp)/"
    $isBinaryArtifact = $rel -match "\.(apk|aab|iml|lock)$"

    -not $isExcludedDir -and -not $isGeneratedArtifact -and -not $isBinaryArtifact
}

if (-not $files -or $files.Count -eq 0) {
    throw "No se encontraron archivos fuente para comprimir."
}

Compress-Archive -Path $files.FullName -DestinationPath $dest -CompressionLevel Optimal
$hash = (Get-FileHash -Algorithm SHA256 $dest).Hash

"SHA256: $hash" | Out-File -FilePath $hashFile -Encoding ascii

Write-Output "ZIP generado: $dest"
Write-Output "SHA256: $hash"
Write-Output "Hash guardado en: $hashFile"
