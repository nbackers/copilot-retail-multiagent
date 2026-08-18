<#
.SYNOPSIS
    Rebrands the skill set from one retailer identity to another.

.DESCRIPTION
    The skills in this repo are written against a fictitious retailer, "Northwind Retail
    Group", with the Dataverse publisher prefix nwr_. This script rewrites that identity
    so you can point the skills at your own schema without hand-editing six files.

    It rewrites, in every SKILL.md:
      - the table prefix (nwr_ -> yours)
      - the retailer name
      - store names

.PARAMETER SkillsPath
    Folder containing the skill subfolders. Defaults to the repo's skills folder.

.PARAMETER Prefix
    Your Dataverse publisher prefix, without the trailing underscore.

.PARAMETER RetailerName
    Your retailer or organisation name.

.PARAMETER StoreNames
    Replacement store names, in place of the three fictitious ones.

.PARAMETER Repackage
    Re-zip each skill folder after rewriting, ready for upload.

.EXAMPLE
    .\Set-SkillBranding.ps1 -Prefix con -RetailerName 'Contoso Retail' -Repackage

.EXAMPLE
    .\Set-SkillBranding.ps1 -Prefix con -RetailerName 'Contoso' -StoreNames 'Northside','Riverton','Eastgate'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $SkillsPath = (Join-Path $PSScriptRoot '..\skills'),

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z][a-z0-9]{1,7}$')]
    [string] $Prefix,

    [Parameter(Mandatory)]
    [string] $RetailerName,

    [ValidateCount(3, 3)]
    [string[]] $StoreNames = @('Northgate', 'Riverside', 'Westfield Park'),

    [switch] $Repackage
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$SkillsPath = (Resolve-Path -LiteralPath $SkillsPath).Path

# Source identity used throughout this repo.
$sourcePrefix = 'nwr'
$sourceRetailer = 'Northwind Retail Group'
$sourceRetailerShort = 'Northwind'
$sourceStores = @('Northgate', 'Riverside', 'Westfield Park')

$replacements = [ordered]@{}
$replacements["${sourcePrefix}_"] = "${Prefix}_"
$replacements[$sourceRetailer] = $RetailerName
$replacements[$sourceRetailerShort] = $RetailerName

for ($i = 0; $i -lt 3; $i++) {
    if ($sourceStores[$i] -ne $StoreNames[$i]) {
        $replacements[$sourceStores[$i]] = $StoreNames[$i]
    }
}

Write-Host ''
Write-Host "Rebranding skills in $SkillsPath" -ForegroundColor Cyan
foreach ($k in $replacements.Keys) {
    Write-Host "  $k -> $($replacements[$k])" -ForegroundColor DarkGray
}
Write-Host ''

$skillDirs = Get-ChildItem -LiteralPath $SkillsPath -Directory
if (-not $skillDirs) { throw "No skill folders found in $SkillsPath" }

foreach ($dir in $skillDirs) {

    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile)) {
        Write-Warning "$($dir.Name): no SKILL.md, skipped."
        continue
    }

    $content = [System.IO.File]::ReadAllText($skillFile)
    $original = $content
    $changeCount = 0

    foreach ($find in $replacements.Keys) {
        $found = [regex]::Matches($content, [regex]::Escape($find))
        if ($found.Count -gt 0) {
            $changeCount += $found.Count
            $content = $content.Replace($find, $replacements[$find])
        }
    }

    if ($content -eq $original) {
        Write-Host "$($dir.Name): no changes needed." -ForegroundColor DarkGray
        continue
    }

    if ($PSCmdlet.ShouldProcess($skillFile, "Apply $changeCount replacement(s)")) {
        # UTF8 without BOM - a BOM breaks front matter parsing on upload.
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($skillFile, $content, $utf8NoBom)
        Write-Host "$($dir.Name): $changeCount replacement(s)." -ForegroundColor Green
    }
}

if ($Repackage) {
    Write-Host ''
    Write-Host 'Repackaging...' -ForegroundColor Cyan

    foreach ($dir in $skillDirs) {
        $zip = Join-Path $SkillsPath "$($dir.Name).zip"
        if ($PSCmdlet.ShouldProcess($zip, 'Create archive')) {
            if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
            # SKILL.md must sit at the archive root, not inside a folder.
            Compress-Archive -Path (Join-Path $dir.FullName '*') -DestinationPath $zip -Force
            Write-Host "  $($dir.Name).zip" -ForegroundColor Green
        }
    }
}

Write-Host ''
Write-Host 'Done. Upload each zip via Copilot Studio > Build > Skills > Add skill.' -ForegroundColor Cyan
Write-Host ''
