# LOCAL FORK CHECK -- not part of upstream superpowers.
#
# OneDrive for Business path-length gate (90% policy).
#
# OneDrive for Business documented limits:
#   - maximum full path : 400 characters
#   - maximum file name : 255 characters
# This fork's rule: never exceed 90% of those limits.
#   - full path  <= 360 characters
#   - file name  <= 229 characters
#
# Windows note: on Windows 11 the binding limit for dependency trees
# (npm and friends) is 260 characters (MAX_PATH) unless LongPathsEnabled
# is set. See windows-onedrive-hardening.md.
#
# This script touches no registries and has no external dependencies.

[CmdletBinding()]
param(
    [int]$MaxPathLength = 360,
    [int]$MaxFileName = 229,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Test-InExcluded {
    param([string]$Path)
    return ($Path -match '(^|[\\/])(\.git|node_modules)([\\/]|$)')
}

$pathOffenders = [System.Collections.Generic.List[string]]::new()
$nameOffenders = [System.Collections.Generic.List[string]]::new()

Get-ChildItem -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue |
  Where-Object { -not (Test-InExcluded $_.FullName) } |
  ForEach-Object {
    if ($_.FullName.Length -gt $MaxPathLength) {
      $pathOffenders.Add($_.FullName)
    }
  }

Get-ChildItem -LiteralPath $Root -Recurse -Force -File -ErrorAction SilentlyContinue |
  Where-Object { -not (Test-InExcluded $_.FullName) } |
  ForEach-Object {
    if ($_.Name.Length -gt $MaxFileName) {
      $nameOffenders.Add($_.FullName)
    }
  }

$failed = $false

if ($pathOffenders.Count -gt 0) {
  $failed = $true
  Write-Host "FAIL: $($pathOffenders.Count) path(s) exceed ${MaxPathLength} characters (90% of the OneDrive for Business 400-char limit):" -ForegroundColor Red
  $pathOffenders | Select-Object -First 50 | ForEach-Object { Write-Host "  $($_.Length) chars: $_" }
  if ($pathOffenders.Count -gt 50) { Write-Host "  ... and $($pathOffenders.Count - 50) more" }
}

if ($nameOffenders.Count -gt 0) {
  $failed = $true
  Write-Host "FAIL: $($nameOffenders.Count) file name(s) exceed ${MaxFileName} characters (90% of the OneDrive for Business 255-char limit):" -ForegroundColor Red
  $nameOffenders | Select-Object -First 50 | ForEach-Object {
    $leaf = Split-Path $_ -Leaf
    Write-Host ('  {0} chars: {1}' -f $leaf.Length, $_)
  }
  if ($nameOffenders.Count -gt 50) { Write-Host "  ... and $($nameOffenders.Count - 50) more" }
}

if (-not $failed) {
  Write-Host "OK: no paths exceed ${MaxPathLength} characters and no file names exceed ${MaxFileName} characters." -ForegroundColor Green
  exit 0
}

exit 1
