#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$AppName     = 'CHITUBOX Dental'
$AppExe      = 'CHITUBOX Dental.exe'
$Printer16K  = 'ELEGOO Saturn 4 Ultra 16K'
$PrinterBase = 'ELEGOO Saturn 4 Ultra'

$ScriptDir       = Split-Path -Parent $PSScriptRoot
$SrcMachine      = Join-Path $ScriptDir 'Data\machinecfg'
$SrcResources    = Join-Path $ScriptDir 'Data\resources'
$TempData        = Join-Path $env:TEMP 'CHITUBOX_Patch_Elegoo_Saturn_4_Ultra_16K'
$UserProfilesDir = Join-Path $env:LOCALAPPDATA "$AppName\default_account"
$BackupDir       = Join-Path $env:LOCALAPPDATA "$AppName\Patch_Backups"

$script:WorkMachine   = $SrcMachine
$script:WorkResources = $SrcResources

function Write-Info    { param([string]$Message) Write-Host "  [*] $Message" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Message) Write-Host "  [+] $Message" -ForegroundColor Green }
function Write-Warn    { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Err     { param([string]$Message) Write-Host "  [-] ERROR: $Message" -ForegroundColor Red }

function Show-Banner {
    Write-Host ''
    Write-Host '  ╔═════════════════════════════════════════════════════════════╗' -ForegroundColor White
    Write-Host '  ║ ELEGOO Saturn 4 Ultra 16K Profile Patch for CHITUBOX Dental ║' -ForegroundColor White
    Write-Host '  ╚═════════════════════════════════════════════════════════════╝' -ForegroundColor White
    Write-Host ''
}

function Show-Success {
    Write-Host ''
    Write-Host '  ╔═════════════════════════════════════════════════════════════╗' -ForegroundColor Green
    Write-Host '  ║                      Operation Complete!                    ║' -ForegroundColor Green
    Write-Host '  ╚═════════════════════════════════════════════════════════════╝' -ForegroundColor Green
    Write-Host ''
}

function Show-Failure {
    Write-Host ''
    Write-Host '  ╔═════════════════════════════════════════════════════════════╗' -ForegroundColor Red
    Write-Host '  ║                 Installation aborted/failed.                ║' -ForegroundColor Red
    Write-Host '  ╚═════════════════════════════════════════════════════════════╝' -ForegroundColor Red
    Write-Host ''
}

function Test-IsAdministrator {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [System.Security.Principal.WindowsPrincipal]::new($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-Mode {
    Write-Host '  ┌───────────────────────────────────────────────────────────┐'
    Write-Host '  │ Select action:                                            │'
    Write-Host '  │                                                           │'
    Write-Host '  │ [1] ADD     - Install 16K as a new printer                │'
    Write-Host '  │ [2] REPLACE - Overwrite existing Saturn 4 Ultra with 16K  │'
    Write-Host '  │ [3] RESTORE - Remove patch and restore original files     │'
    Write-Host '  └───────────────────────────────────────────────────────────┘'
    Write-Host ''
    while ($true) {
        Write-Host -NoNewline '  Your choice [1/2/3]: '
        $key = [System.Console]::ReadKey($true)
        Write-Host $key.KeyChar
        switch ($key.KeyChar) {
            '1' { return 'add' }
            '2' { return 'replace' }
            '3' { return 'restore' }
        }
    }
}

function Test-SourceFiles {
    Write-Info 'Validating source directories...'
    if (-not (Test-Path -LiteralPath $SrcMachine -PathType Container)) {
        throw 'Missing directory: Data\machinecfg'
    }
    if (-not (Test-Path -LiteralPath $SrcResources -PathType Container)) {
        throw 'Missing directory: Data\resources'
    }
    Write-Ok 'Source directories validated.'
}

function Find-InstallDir {
    Write-Info "Searching for $AppName in Windows Registry..."
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($k in $keys) {
        $items = Get-ChildItem -LiteralPath $k -ErrorAction SilentlyContinue
        foreach ($i in $items) {
            $p = Get-ItemProperty -LiteralPath $i.PSPath -ErrorAction SilentlyContinue
            if ($p.DisplayName -eq $AppName -and $p.InstallLocation) {
                $loc = $p.InstallLocation.TrimEnd('\')
                if (Test-Path -LiteralPath (Join-Path $loc $AppExe)) {
                    return $loc
                }
            }
        }
    }
    return $null
}

function New-Backup {
    param([Parameter(Mandatory)][string]$InstallDir)

    Write-Info 'Checking original files backup...'
    if (-not (Test-Path -LiteralPath $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    if (Test-Path -LiteralPath (Join-Path $BackupDir 'list.cfgx')) {
        Write-Info 'Backup already exists. Skipping backup step.'
        return
    }

    $sources = [ordered]@{
        'list.cfgx'           = Join-Path $InstallDir 'machinecfg\list.cfgx'
        "$PrinterBase.cfgd"   = Join-Path $InstallDir "machinecfg\Elegoo\$PrinterBase.cfgd"
        "$PrinterBase.png"    = Join-Path $InstallDir "machinecfg\Elegoo\$PrinterBase.png"
        "$PrinterBase.stl"    = Join-Path $InstallDir "resources\model\MachineModel\$PrinterBase.stl"
    }

    foreach ($e in $sources.GetEnumerator()) {
        if (-not (Test-Path -LiteralPath $e.Value)) {
            throw "Original file not found: $($e.Key). Reinstall $AppName."
        }
    }

    foreach ($e in $sources.GetEnumerator()) {
        Copy-Item -LiteralPath $e.Value -Destination (Join-Path $BackupDir $e.Key) -Force
    }

    Write-Ok 'Original files backed up securely.'
}

function Invoke-Restore {
    param([Parameter(Mandatory)][string]$InstallDir)

    Write-Info 'Restoring original application state...'

    $backupList = Join-Path $BackupDir 'list.cfgx'
    if (-not (Test-Path -LiteralPath $backupList)) {
        Write-Err  'No backup found! Cannot restore original files.'
        Write-Warn 'If the program behaves incorrectly, reinstall CHITUBOX Dental.'
        throw 'Backup missing'
    }

    $appElegoo = Join-Path $InstallDir 'machinecfg\Elegoo'
    $appModels = Join-Path $InstallDir 'resources\model\MachineModel'

    Remove-Item -LiteralPath (Join-Path $appElegoo "$Printer16K.cfgd") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $appElegoo "$Printer16K.png")  -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $appModels "$Printer16K.stl")  -Force -ErrorAction SilentlyContinue

    Copy-Item -LiteralPath $backupList                               -Destination (Join-Path $InstallDir 'machinecfg\list.cfgx') -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $BackupDir "$PrinterBase.cfgd") -Destination (Join-Path $appElegoo "$PrinterBase.cfgd")     -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $BackupDir "$PrinterBase.png")  -Destination (Join-Path $appElegoo "$PrinterBase.png")      -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $BackupDir "$PrinterBase.stl")  -Destination (Join-Path $appModels "$PrinterBase.stl")      -Force -ErrorAction SilentlyContinue

    Write-Ok 'Application folder restored.'

    if (Test-Path -LiteralPath $UserProfilesDir) {
        Get-ChildItem -LiteralPath $UserProfilesDir -Directory |
            Where-Object { $_.Name -ne 'mask_image' } |
            ForEach-Object {
                $pElegoo = Join-Path $_.FullName 'machinecfg\Elegoo'
                Remove-Item -LiteralPath (Join-Path $pElegoo "$Printer16K.cfgd") -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath (Join-Path $pElegoo "$Printer16K.png")  -Force -ErrorAction SilentlyContinue
                Copy-Item -LiteralPath $backupList                                -Destination (Join-Path $_.FullName 'machinecfg\list.cfgx') -Force -ErrorAction SilentlyContinue
                Copy-Item -LiteralPath (Join-Path $BackupDir "$PrinterBase.cfgd") -Destination (Join-Path $pElegoo "$PrinterBase.cfgd")       -Force -ErrorAction SilentlyContinue
                Copy-Item -LiteralPath (Join-Path $BackupDir "$PrinterBase.png")  -Destination (Join-Path $pElegoo "$PrinterBase.png")        -Force -ErrorAction SilentlyContinue
            }
        Write-Ok 'User profiles restored.'
    }
}

function New-ReplaceFiles {
    Write-Info "Preparing 'Replace' mode data (stripping '16K' identifiers)..."

    if (Test-Path -LiteralPath $TempData) {
        Remove-Item -LiteralPath $TempData -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempData -Force | Out-Null

    Copy-Item -LiteralPath $SrcMachine   -Destination (Join-Path $TempData 'machinecfg') -Recurse -Force
    Copy-Item -LiteralPath $SrcResources -Destination (Join-Path $TempData 'resources')  -Recurse -Force

    $tList = Join-Path $TempData 'machinecfg\list.cfgx'
    if (Test-Path -LiteralPath $tList) { Remove-Item -LiteralPath $tList -Force }

    $tMach = Join-Path $TempData 'machinecfg\Elegoo'
    $tModl = Join-Path $TempData 'resources\model\MachineModel'

    $renames = @(
        @{ Src = Join-Path $tMach "$Printer16K.cfgd"; Dst = Join-Path $tMach "$PrinterBase.cfgd" }
        @{ Src = Join-Path $tMach "$Printer16K.png" ; Dst = Join-Path $tMach "$PrinterBase.png"  }
        @{ Src = Join-Path $tModl "$Printer16K.stl" ; Dst = Join-Path $tModl "$PrinterBase.stl"  }
    )
    foreach ($r in $renames) {
        if (Test-Path -LiteralPath $r.Src) {
            Move-Item -LiteralPath $r.Src -Destination $r.Dst -Force
        }
    }

    $cfgd = Join-Path $tMach "$PrinterBase.cfgd"
    if (-not (Test-Path -LiteralPath $cfgd)) {
        throw "Source file missing after rename: $cfgd"
    }
    $content = [System.IO.File]::ReadAllText($cfgd)
    $content = $content.Replace($Printer16K, $PrinterBase)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($cfgd, $content, $utf8NoBom)

    Write-Ok 'Temporary files prepared.'

    $script:WorkMachine   = Join-Path $TempData 'machinecfg'
    $script:WorkResources = Join-Path $TempData 'resources'
}

function Copy-Tree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Invoke-DeployToAppFolder {
    param([Parameter(Mandatory)][string]$InstallDir)

    Write-Info 'Deploying files to application directory...'

    Copy-Tree -Source $script:WorkMachine   -Destination (Join-Path $InstallDir 'machinecfg')
    Write-Ok 'machinecfg  -> Application Folder'

    Copy-Tree -Source $script:WorkResources -Destination (Join-Path $InstallDir 'resources')
    Write-Ok 'resources   -> Application Folder'
}

function Invoke-DeployToUserProfiles {
    Write-Info 'Deploying machine configuration to user profiles...'

    if (-not (Test-Path -LiteralPath $UserProfilesDir)) {
        Write-Warn 'No user profiles found. Skipping profile injection.'
        return
    }

    $count = 0
    Get-ChildItem -LiteralPath $UserProfilesDir -Directory |
        Where-Object { $_.Name -ne 'mask_image' } |
        ForEach-Object {
            Copy-Tree -Source $script:WorkMachine -Destination (Join-Path $_.FullName 'machinecfg')
            Write-Ok "Profile updated: $($_.Name)"
            $count++
        }

    if ($count -eq 0) {
        Write-Warn 'No valid profiles matched for injection.'
    }
}

function Invoke-Cleanup {
    if (Test-Path -LiteralPath $TempData) {
        Remove-Item -LiteralPath $TempData -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------- main ----------
try {
    if (-not (Test-IsAdministrator)) {
        Write-Host ''
        Write-Host '  [X] Access Denied!' -ForegroundColor Red
        Write-Host '  [!] This patch must be run as an Administrator to modify program files.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Right-click "Install.bat" and select "Run as administrator".'
        Write-Host ''
        exit 1
    }

    Show-Banner
    $mode = Read-Mode

    Write-Host ''
    switch ($mode) {
        'add'     { Write-Ok 'Mode selected: ADD (New Printer)' }
        'replace' { Write-Ok 'Mode selected: REPLACE (Overwrite Original)' }
        'restore' { Write-Ok 'Mode selected: RESTORE (Remove Patch)' }
    }

    if ($mode -ne 'restore') {
        Write-Host ''
        Test-SourceFiles
    }

    Write-Host ''
    $installDir = Find-InstallDir
    if (-not $installDir) {
        throw "$AppName installation not found!"
    }
    Write-Ok "Found installation at: $installDir"

    if ($mode -eq 'restore') {
        Write-Host ''
        Invoke-Restore -InstallDir $installDir
    }
    else {
        Write-Host ''
        New-Backup -InstallDir $installDir

        if ($mode -eq 'replace') {
            Write-Host ''
            New-ReplaceFiles
        }

        Write-Host ''
        Invoke-DeployToAppFolder -InstallDir $installDir
        Write-Host ''
        Invoke-DeployToUserProfiles
    }

    Invoke-Cleanup
    Show-Success
    exit 0
}
catch {
    Write-Err $_.Exception.Message
    Invoke-Cleanup
    Show-Failure
    exit 1
}
