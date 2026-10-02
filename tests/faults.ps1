# Inject failures in the child installer process without changing production code.
function Test-InstallerFault([string]$Operation, [string]$Source, [string]$Destination) {
    $fault = $env:WHOLETEAM_FAULT
    if (-not $fault -or (Test-Path -LiteralPath $env:WHOLETEAM_FAULT_FIRED)) { return '' }
    $parts = $fault -split ':', 2
    $kind = $parts[0]
    $suffixes = @{
        core = '/factory/core'
        claude = '/.claude/agents/factory-architect.md'
        codex = '/.codex/agents/factory-architect.toml'
        guide = '/AGENTS.md'
        starter = '/new-starting-file.txt'
    }
    $sourcePath = $Source -replace '\\', '/'
    $targetPath = $Destination -replace '\\', '/'
    $matches = $false
    if ($Operation -eq 'copy' -and @('copy', 'corrupt', 'stage-interrupt', 'pause') -contains $kind) {
        $matches = $sourcePath.EndsWith($suffixes[$parts[1]])
    } elseif ($Operation -eq 'move' -and @('move', 'interrupt') -contains $kind) {
        $matches = $sourcePath.EndsWith('/new') -and $targetPath.EndsWith($suffixes[$parts[1]])
    } elseif ($Operation -eq 'move' -and @('recover', 'recover-interrupt') -contains $kind) {
        $matches = $sourcePath.EndsWith('/old') -and $targetPath.EndsWith($suffixes[$parts[1]])
    } elseif ($Operation -eq 'remove' -and $kind -eq 'cleanup-interrupt') {
        $matches = $sourcePath.EndsWith('/.wholeteam-update')
    }
    if (-not $matches) { return '' }
    [System.IO.File]::WriteAllText($env:WHOLETEAM_FAULT_FIRED, $fault)
    if ($kind -eq 'pause') {
        $release = Join-Path (Split-Path -Parent $env:WHOLETEAM_FAULT_FIRED) 'fault-release'
        while (-not (Test-Path -LiteralPath $release)) { Start-Sleep -Milliseconds 20 }
        return ''
    }
    if ($kind -eq 'corrupt') { return $kind }
    if ($kind -like '*interrupt*') {
        if ($kind -eq 'cleanup-interrupt') {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath (Join-Path $Source 'entries/000001') -Recurse -Force
        }
        Stop-Process -Id $PID -Force
    }
    throw "Injected $fault failure"
}

function Copy-Item {
    [CmdletBinding()]
    param([string]$LiteralPath, [string]$Destination, [switch]$Recurse, [switch]$Force)
    if ((Test-InstallerFault 'copy' $LiteralPath $Destination) -eq 'corrupt') {
        if ($Recurse) {
            New-Item -ItemType Directory -Path $Destination | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $Destination 'FACTORY.md'), "Incomplete copy`n")
        } else { [System.IO.File]::WriteAllText($Destination, "Incomplete copy`n") }
        return
    }
    Microsoft.PowerShell.Management\Copy-Item @PSBoundParameters
}

function Move-Item {
    [CmdletBinding()]
    param([string]$LiteralPath, [string]$Destination, [switch]$Force)
    $null = Test-InstallerFault 'move' $LiteralPath $Destination
    Microsoft.PowerShell.Management\Move-Item @PSBoundParameters
}

function Remove-Item {
    [CmdletBinding()]
    param([string]$LiteralPath, [switch]$Recurse, [switch]$Force)
    $null = Test-InstallerFault 'remove' $LiteralPath ''
    Microsoft.PowerShell.Management\Remove-Item @PSBoundParameters
}

& $env:WHOLETEAM_INSTALLER -Path $env:WHOLETEAM_PROJECT -Yes
exit $LASTEXITCODE
