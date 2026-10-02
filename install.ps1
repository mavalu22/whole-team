# WholeTeam installer for Windows PowerShell 5.1+ and PowerShell 7+.
# Copies the factory into an existing git project, or updates an installed one.
# Requires only PowerShell and git. See README.md, section "Install".
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Path <project>] [-Type new|ongoing] [-Mode install|update] [-Yes] [-Help]

param(
    [string]$Path = "",
    [string]$Type = "",
    [string]$Mode = "",
    [switch]$Yes,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$BlockBeginMd = '<!-- >>> whole-team >>> -->'
$BlockEndMd = '<!-- <<< whole-team <<< -->'
$BlockBeginIgnore = '# >>> whole-team >>>'
$BlockEndIgnore = '# <<< whole-team <<<'
$GuideFiles = @('CLAUDE.md', 'AGENTS.md', 'CLAUDE.local.md', 'AGENTS.override.md')
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$script:Project = ""
$script:OldManifest = @()
$script:RootMode = 'install'
$script:NewManifest = New-Object System.Collections.ArrayList
$script:UpdateDir = ''
$script:UpdateCount = 0

function Show-Usage {
    $text = @'
Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1 [-Path <project>] [-Type new|ongoing] [-Mode install|update] [-Yes] [-Help]

Installs WholeTeam into an existing git project, or updates an installed one.

Options:
  -Path <project>   Project folder (must already be a git repository).
  -Type <type>      new     = a new product; Discovery starts from the idea.
                    ongoing = an existing codebase; Discovery starts by analysing the code.
  -Mode <mode>      install or update. Detected automatically when omitted.
  -Yes              Accept defaults and never prompt. Fails if the path is missing.
  -Help             Show this help.

Any missing value is asked interactively.
'@
    Write-Host $text
}

function Write-Info([string]$Message) { Write-Host $Message }
function Write-Warn([string]$Message) { [Console]::Error.WriteLine("Warning: $Message") }
function Fail([string]$Message) {
    throw $Message
}

function Read-Answer([string]$Prompt, [string]$Default) {
    if ($Yes) { return $Default }
    $answer = Read-Host $Prompt
    if ($null -eq $answer -or $answer -eq '') { return $Default }
    return $answer
}

function Confirm-Choice([string]$Prompt) {
    $answer = Read-Answer "$Prompt [Y/n]" 'y'
    return -not ($answer -match '^(n|no)$')
}

function Read-Text([string]$File) { return [System.IO.File]::ReadAllText($File) }
function Write-Text([string]$File, [string]$Text) { [System.IO.File]::WriteAllText($File, $Text, $Utf8NoBom) }

function Invoke-Git([string[]]$GitArgs) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @GitArgs 2>$null
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    return New-Object PSObject -Property @{ Code = $code; Out = $output }
}

function Get-FullPath([string]$Candidate) {
    $resolved = (Resolve-Path -LiteralPath $Candidate).ProviderPath
    if ($resolved.Length -gt 1) {
        $trimmed = $resolved.TrimEnd('\', '/')
        if ($trimmed -eq '') { $trimmed = '/' }
        if ($trimmed -match '^[A-Za-z]:$') { $trimmed = $trimmed + '\' }
        $resolved = $trimmed
    }
    return $resolved
}

# Trim, strip one pair of wrapping quotes, expand a leading ~, resolve to an absolute path.
function Get-NormalizedPath([string]$Raw) {
    $p = $Raw.Trim()
    if ($p.Length -ge 2) {
        if (($p.StartsWith('"') -and $p.EndsWith('"')) -or ($p.StartsWith("'") -and $p.EndsWith("'"))) {
            $p = $p.Substring(1, $p.Length - 2)
        }
    }
    if ($p -eq '~') {
        $p = $HOME
    } elseif ($p.StartsWith('~/') -or $p.StartsWith('~\')) {
        $p = [System.IO.Path]::Combine($HOME, $p.Substring(2))
    }
    if ($p -ne '' -and (Test-Path -LiteralPath $p -PathType Container)) {
        return Get-FullPath $p
    }
    return $p
}

function Join-ProjectPath([string]$Relative) {
    return [System.IO.Path]::Combine($script:Project, $Relative)
}

function Test-Tracked([string]$Relative) {
    $result = Invoke-Git @('-C', $script:Project, 'ls-files', '--error-unmatch', '--', $Relative)
    return ($result.Code -eq 0)
}

function Get-LineText([string]$Line) { return $Line.TrimEnd("`r") }

# Find the block markers. Indexes are -1 when absent; End is the first end marker after Begin.
# Marker lines are compared with a trailing carriage return removed.
function Get-BlockLines([string]$File, [string]$Begin, [string]$End) {
    $lines = (Read-Text $File) -split "`n"
    $beginIndex = -1
    $endIndex = -1
    $anyEnd = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = Get-LineText $lines[$i]
        if ($line -ceq $End) { $anyEnd = $true }
        if ($beginIndex -lt 0 -and $line -ceq $Begin) {
            $beginIndex = $i
        } elseif ($beginIndex -ge 0 -and $endIndex -lt 0 -and $line -ceq $End) {
            $endIndex = $i
        }
    }
    return New-Object PSObject -Property @{ Begin = $beginIndex; End = $endIndex; AnyEnd = $anyEnd }
}

# Stop when the file has an incomplete block.
function Assert-Block([string]$File, [string]$Begin, [string]$End) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { return }
    $found = Get-BlockLines $File $Begin $End
    if ($found.Begin -ge 0 -and $found.End -ge 0) { return }
    if ($found.Begin -lt 0 -and -not $found.AnyEnd) { return }
    Fail "$File has an incomplete WholeTeam block (one marker is missing). Fix or remove the markers, then run the installer again."
}

# Replace the text between the markers, or append the block after a blank line.
function Update-Block([string]$File, [string]$BlockText, [string]$Begin, [string]$End) {
    if ($script:UpdateDir -ne '') { $File = New-StagedFile $File }
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Text $File $BlockText
        return
    }
    Assert-Block $File $Begin $End
    $content = Read-Text $File
    $lines = $content -split "`n"
    $found = Get-BlockLines $File $Begin $End
    if ($found.Begin -ge 0) {
        $blockLines = $BlockText -split "`n"
        $output = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $found.Begin; $i++) { [void]$output.Add($lines[$i]) }
        for ($i = 0; $i -lt ($blockLines.Count - 1); $i++) { [void]$output.Add($blockLines[$i]) }
        for ($i = $found.End + 1; $i -lt $lines.Count; $i++) { [void]$output.Add($lines[$i]) }
        Write-Text $File ([string]::Join("`n", $output.ToArray()))
    } else {
        $output = $content
        if ($output.Length -gt 0) {
            if (-not $output.EndsWith("`n")) { $output = $output + "`n" }
            $output = $output + "`n"
        }
        Write-Text $File ($output + $BlockText)
    }
}

function Get-ManifestStatus([string]$Relative) {
    foreach ($entry in $script:OldManifest) {
        if ($entry.File -eq $Relative) { return $entry.Action }
    }
    return ''
}

function Test-ManifestHas([string]$Relative) {
    return ((Get-ManifestStatus $Relative) -ne '')
}

function Add-Record([string]$Action, [string]$Relative) {
    if ((Get-ManifestStatus $Relative) -eq 'created') { $Action = 'created' }
    [void]$script:NewManifest.Add((New-Object PSObject -Property @{ Action = $Action; File = $Relative }))
}

function Read-Manifest([string]$File) {
    $entries = @()
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        foreach ($raw in ((Read-Text $File) -split "`n")) {
            $line = (Get-LineText $raw).Trim()
            if ($line -eq '') { continue }
            $parts = $line -split ' ', 2
            if ($parts.Count -eq 2) {
                $entries += New-Object PSObject -Property @{ Action = $parts[0]; File = $parts[1] }
            }
        }
    }
    return ,$entries
}

# A journal entry holds a target, a staged replacement and, after promotion,
# the original in "old". All copies finish before "ready" allows any changes.
function New-UpdateTarget([string]$Target) {
    $script:UpdateCount++
    $entry = [System.IO.Path]::Combine($script:UpdateDir, 'entries', ('{0:D6}' -f $script:UpdateCount))
    New-Item -ItemType Directory -Path $entry -Force | Out-Null
    $relative = $Target
    $prefix = $script:Project + [System.IO.Path]::DirectorySeparatorChar
    if ($Target.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $Target.Substring($prefix.Length) -replace '\\', '/'
    }
    Write-Text (Join-Path $entry 'target') ($relative + "`n")
    if (-not (Test-Path -LiteralPath $Target)) { Write-Text (Join-Path $entry 'absent') '' }
    return Join-Path $entry 'new'
}

function Assert-StagedCopy([string]$Source, [string]$Destination) {
    $result = Invoke-Git @('diff', '--no-index', '--quiet', '--no-ext-diff', '--no-textconv', '--', $Source, $Destination)
    if ($result.Code -ne 0) { Fail "Staged copy validation failed for $Source. The installed version has not changed." }
}

function New-StagedFile([string]$Target) {
    $staged = New-UpdateTarget $Target
    if (Test-Path -LiteralPath $Target) {
        if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) { Fail "Expected a file at $Target." }
        Copy-Item -LiteralPath $Target -Destination $staged -Force
        Assert-StagedCopy $Target $staged
    }
    return $staged
}

# An original already moved back during recovery is left alone on retry.
# Keep the journal on any restoration failure so the next run can retry safely.
function Restore-Update {
    $dir = Join-ProjectPath 'factory/.wholeteam-update'
    if (-not (Test-Path -LiteralPath $dir)) { return }
    $format = Join-Path $dir 'format'
    if (-not (Test-Path -LiteralPath $format -PathType Leaf) -or (Read-Text $format).Trim() -ne 'wholeteam-update-v1') {
        Fail "Unrecognized update directory: $dir. Keep its contents and move it aside before retrying."
    }
    if ($script:UpdateDir -eq '') {
        $ownerFile = Join-Path $dir 'owner'
        if (-not (Test-Path -LiteralPath $ownerFile -PathType Leaf)) { Fail "Update owner is missing in $dir; keep the journal for recovery." }
        $owner = (Read-Text $ownerFile).Trim() -split ' '
        $ownerPid = 0
        if ($owner.Count -ne 2 -or -not [int]::TryParse($owner[1], [ref]$ownerPid) -or $ownerPid -le 0) {
            Fail "Invalid update owner in $dir."
        }
        $runtime = 'unix'
        if ($env:OS -eq 'Windows_NT') { $runtime = 'powershell' }
        if ($owner[0] -ne $runtime) { Fail "Use the $($owner[0]) installer to recover $dir safely." }
        if (Get-Process -Id $ownerPid -ErrorAction SilentlyContinue) { Fail "Another WholeTeam update is still running (process $ownerPid)." }
    }
    $ready = Join-Path $dir 'ready'
    if ((Test-Path -LiteralPath $ready) -and -not (Test-Path -LiteralPath (Join-Path $dir 'committed'))) {
        Write-Info 'Recovering an unfinished WholeTeam update ...'
        foreach ($entry in (Get-ChildItem -LiteralPath (Join-Path $dir 'entries') -Directory | Sort-Object Name)) {
            $target = Get-IgnorePath ((Read-Text (Join-Path $entry.FullName 'target')).TrimEnd("`r", "`n"))
            $old = Join-Path $entry.FullName 'old'
            if (Test-Path -LiteralPath $old) {
                if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
                Move-Item -LiteralPath $old -Destination $target
            } elseif ((Test-Path -LiteralPath (Join-Path $entry.FullName 'absent')) -and -not (Test-Path -LiteralPath (Join-Path $entry.FullName 'new'))) {
                if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            }
        }
        Write-Info 'The previous WholeTeam version was restored.'
    }
    # "ready" must disappear before backups do, including interrupted cleanup.
    if (Test-Path -LiteralPath $ready) { Remove-Item -LiteralPath $ready -Force }
    Remove-Item -LiteralPath $dir -Recurse -Force
    $script:UpdateDir = ''
}

function Complete-Update {
    $dir = $script:UpdateDir
    Write-Text (Join-Path $dir 'ready.tmp') ''
    Move-Item -LiteralPath (Join-Path $dir 'ready.tmp') -Destination (Join-Path $dir 'ready')
    foreach ($entry in (Get-ChildItem -LiteralPath (Join-Path $dir 'entries') -Directory | Sort-Object Name)) {
        $target = Get-IgnorePath ((Read-Text (Join-Path $entry.FullName 'target')).TrimEnd("`r", "`n"))
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        if (Test-Path -LiteralPath (Join-Path $entry.FullName 'absent')) {
            if (Test-Path -LiteralPath $target) { Fail "Update target appeared during staging: $target." }
        } else {
            if (-not (Test-Path -LiteralPath $target)) { Fail "Update target disappeared during staging: $target." }
            Move-Item -LiteralPath $target -Destination (Join-Path $entry.FullName 'old')
        }
        $staged = Join-Path $entry.FullName 'new'
        if (Test-Path -LiteralPath $staged) { Move-Item -LiteralPath $staged -Destination $target }
    }
    Write-Text (Join-Path $dir 'committed.tmp') ''
    Move-Item -LiteralPath (Join-Path $dir 'committed.tmp') -Destination (Join-Path $dir 'committed')
    Restore-Update
}

# Section 4.3 rules for one tool's guide file and its local-only fallback.
function Stop-BothTracked([string]$Main, [string]$Fallback, [string]$BlockFile) {
    Fail "$Main and $Fallback are both tracked by git. Untrack $Fallback (git rm --cached $Fallback), or paste the block from $BlockFile into it by hand, then run the installer again."
}

function Set-GuideFile([string]$Main, [string]$Fallback, [string]$BlockFile) {
    $block = Read-Text $BlockFile
    $mainPath = Join-ProjectPath $Main
    $fallbackPath = Join-ProjectPath $Fallback
    if (-not (Test-Path -LiteralPath $mainPath)) {
        Update-Block $mainPath $block $BlockBeginMd $BlockEndMd
        Add-Record 'created' $Main
    } elseif (-not (Test-Tracked $Main)) {
        Update-Block $mainPath $block $BlockBeginMd $BlockEndMd
        Add-Record 'block' $Main
    } else {
        if (Test-Tracked $Fallback) {
            Stop-BothTracked $Main $Fallback $BlockFile
        }
        if (Test-Path -LiteralPath $fallbackPath) {
            Update-Block $fallbackPath $block $BlockBeginMd $BlockEndMd
            Add-Record 'block' $Fallback
        } else {
            Update-Block $fallbackPath $block $BlockBeginMd $BlockEndMd
            Add-Record 'created' $Fallback
        }
        Write-Info "  $Main is tracked by git: left untouched; the WholeTeam block is in $Fallback."
    }
}

# Section 4.4 block, listing only the guide files the factory created.
function Get-IgnoreBlock {
    $lines = @($BlockBeginIgnore, '/factory/', '/.claude/agents/factory-*.md', '/.codex/agents/factory-*.toml')
    foreach ($name in $GuideFiles) {
        foreach ($entry in $script:NewManifest) {
            if ($entry.Action -eq 'created' -and $entry.File -eq $name) { $lines += "/$name" }
        }
    }
    $lines += $BlockEndIgnore
    return ([string]::Join("`n", $lines) + "`n")
}

# Where the ignore block lives: .gitignore, or the file the old manifest names.
function Get-IgnoreTarget {
    foreach ($entry in $script:OldManifest) {
        if ($GuideFiles -notcontains $entry.File) { return $entry.File }
    }
    return '.gitignore'
}

function Get-IgnorePath([string]$Target) {
    if ([System.IO.Path]::IsPathRooted($Target)) { return $Target }
    return Join-ProjectPath $Target
}

function Set-IgnoreBlock {
    $target = Get-IgnoreTarget
    $absolute = Get-IgnorePath $target
    $block = Get-IgnoreBlock
    if (-not (Test-Path -LiteralPath $absolute)) {
        $parent = Split-Path -Parent $absolute
        if ($script:UpdateDir -eq '' -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Update-Block $absolute $block $BlockBeginIgnore $BlockEndIgnore
        Add-Record 'created' $target
    } else {
        Update-Block $absolute $block $BlockBeginIgnore $BlockEndIgnore
        Add-Record 'block' $target
    }
}

function Set-RootFiles([string]$RunMode) {
    $script:NewManifest = New-Object System.Collections.ArrayList
    $template = $script:Template
    if ($RunMode -eq 'install' -or (Test-ManifestHas 'CLAUDE.md') -or (Test-ManifestHas 'CLAUDE.local.md')) {
        Set-GuideFile 'CLAUDE.md' 'CLAUDE.local.md' ([System.IO.Path]::Combine($template, 'root', 'CLAUDE.md'))
    }
    if ($RunMode -eq 'install' -or (Test-ManifestHas 'AGENTS.md') -or (Test-ManifestHas 'AGENTS.override.md')) {
        Set-GuideFile 'AGENTS.md' 'AGENTS.override.md' ([System.IO.Path]::Combine($template, 'root', 'AGENTS.md'))
    }
    Set-IgnoreBlock
    $text = ''
    foreach ($entry in $script:NewManifest) { $text += "$($entry.Action) $($entry.File)`n" }
    $manifest = Join-ProjectPath 'factory/.install-manifest'
    if ($script:UpdateDir -ne '') { $manifest = New-StagedFile $manifest }
    Write-Text $manifest $text
}

# Set OldManifest and RootMode for the root files.
# RootMode is 'update' only when an update finds a non-empty manifest.
function Initialize-OldManifest([string]$RunMode) {
    $script:OldManifest = @()
    $script:RootMode = 'install'
    if ($RunMode -eq 'update') {
        $manifestPath = Join-ProjectPath 'factory/.install-manifest'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            Write-Warn 'factory/.install-manifest is missing; the root files are handled as in a new install.'
        }
        $script:OldManifest = Read-Manifest $manifestPath
        if ($script:OldManifest.Count -gt 0) { $script:RootMode = 'update' }
    }
}

# Take the decisions Set-RootFiles will take, without writing,
# and stop before the first write when one of them would fail.
function Test-RootFiles {
    $pairs = @(@('CLAUDE.md', 'CLAUDE.local.md'), @('AGENTS.md', 'AGENTS.override.md'))
    foreach ($pair in $pairs) {
        $main = $pair[0]
        $fallback = $pair[1]
        if ($script:RootMode -eq 'update' -and -not (Test-ManifestHas $main) -and -not (Test-ManifestHas $fallback)) { continue }
        $target = $main
        if ((Test-Path -LiteralPath (Join-ProjectPath $main)) -and (Test-Tracked $main)) {
            if (Test-Tracked $fallback) {
                Stop-BothTracked $main $fallback ([System.IO.Path]::Combine($script:Template, 'root', $main))
            }
            $target = $fallback
        }
        Assert-Block (Join-ProjectPath $target) $BlockBeginMd $BlockEndMd
    }
    Assert-Block (Get-IgnorePath (Get-IgnoreTarget)) $BlockBeginIgnore $BlockEndIgnore
}

function Show-RootSummary {
    Write-Info 'Root files:'
    foreach ($entry in (Read-Manifest (Join-ProjectPath 'factory/.install-manifest'))) {
        if ($entry.Action -eq 'created') {
            Write-Info "  created    $($entry.File)"
        } else {
            Write-Info "  block in   $($entry.File)"
        }
    }
}

function Set-ConfigType([string]$ProjectType) {
    $file = Join-ProjectPath 'factory/config.yaml'
    $lines = (Read-Text $file) -split "`n"
    $inProject = $false
    $done = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^project:') { $inProject = $true; continue }
        if ($inProject -and $line -match '^[^ #]') { $inProject = $false }
        if ($inProject -and -not $done -and $line -match '^  type:') {
            $lines[$i] = "  type: $ProjectType"
            $done = $true
        }
    }
    if (-not $done) { Fail "Could not set project.type in $file." }
    Write-Text $file ([string]::Join("`n", $lines))
}

function Set-StateVersion {
    $file = Join-ProjectPath 'factory/state.yaml'
    $lines = (Read-Text $file) -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^factory_version:') {
            $lines[$i] = "factory_version: `"$script:Version`""
            break
        }
    }
    Write-Text $file ([string]::Join("`n", $lines))
}

function Copy-Agents {
    $pairs = @(@('.claude', 'factory-*.md'), @('.codex', 'factory-*.toml'))
    foreach ($pair in $pairs) {
        $targetDir = Join-ProjectPath ([System.IO.Path]::Combine($pair[0], 'agents'))
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        Get-ChildItem -LiteralPath $targetDir -Filter $pair[1] -File | Remove-Item -Force
        $sourceDir = [System.IO.Path]::Combine($script:Template, 'root', $pair[0], 'agents')
        Get-ChildItem -LiteralPath $sourceDir -Filter $pair[1] -File | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination ([System.IO.Path]::Combine($targetDir, $_.Name)) -Force
        }
    }
    Write-ModelsMarker (Join-ProjectPath 'factory/.models-sync-needed')
}

function Write-ModelsMarker([string]$File) {
    $marker = 'The WholeTeam installer rewrote the agent files with default models.' + "`n" +
        'On the next `Let''s code`, the Orchestrator re-applies the models block of factory/config.yaml and deletes this file.' + "`n"
    Write-Text $File $marker
}

function Write-CoreVersion {
    Write-Text (Join-ProjectPath 'factory/core/VERSION') ("$script:Version" + "`n")
}

function Get-GitignoreState {
    if (-not (Test-Tracked '.gitignore')) { return '' }
    $result = Invoke-Git @('-C', $script:Project, 'diff', '--quiet', '--', '.gitignore')
    if ($result.Code -eq 0) { return 'clean' }
    return 'dirty'
}

function Invoke-Install {
    $projectType = $Type
    if ($projectType -eq '') {
        if ($Yes) {
            $projectType = 'new'
        } else {
            Write-Info ''
            Write-Info 'Project type:'
            Write-Info '  1) new      A new product; Discovery starts from the idea.'
            Write-Info '  2) ongoing  An existing codebase; Discovery starts by analysing the code.'
            while ($projectType -eq '') {
                $choice = Read-Answer 'Choose 1 or 2 [1]' '1'
                if ($choice -eq '1' -or $choice -eq 'new') { $projectType = 'new' }
                elseif ($choice -eq '2' -or $choice -eq 'ongoing') { $projectType = 'ongoing' }
                else { Write-Warn 'Please answer 1 (new) or 2 (ongoing).' }
            }
        }
    }

    Write-Info ''
    Write-Info "Installing WholeTeam $script:Version into $script:Project (type: $projectType) ..."
    Copy-Item -LiteralPath ([System.IO.Path]::Combine($script:Template, 'factory')) -Destination (Join-ProjectPath 'factory') -Recurse
    Write-CoreVersion
    Set-ConfigType $projectType
    Set-StateVersion
    Copy-Agents
    Set-RootFiles 'install'

    Write-Info ''
    Write-Info "WholeTeam $script:Version is installed."
    Show-RootSummary
    Write-Info ''
    Write-Info 'Next steps:'
    Write-Info "  1. Open the project in VS Code:  code `"$script:Project`""
    Write-Info '  2. Start Claude Code (claude) or Codex (codex) in the project root.'
    Write-Info "     Recommended main-session model: Claude Code 'sonnet'; Codex 'gpt-6-sol' at medium effort."
    Write-Info "  3. Type: Let's code"
    Write-Info ''
    Write-Info 'Factory files live in factory/, which git ignores. Back that folder up.'
}

function Invoke-Update {
    $installed = (Read-Text (Join-ProjectPath 'factory/core/VERSION')).Trim()
    Write-Info ''
    Write-Info "Updating WholeTeam $installed -> $script:Version in $script:Project ..."

    # Reserve a fresh journal; never reuse unrelated contents at this path.
    $dir = Join-ProjectPath 'factory/.wholeteam-update'
    New-Item -ItemType Directory -Path $dir | Out-Null
    $script:UpdateDir = $dir
    $runtime = 'unix'
    if ($env:OS -eq 'Windows_NT') { $runtime = 'powershell' }
    Write-Text (Join-Path $dir 'owner') ("$runtime $PID" + "`n")
    Write-Text (Join-Path $dir 'format') "wholeteam-update-v1`n"
    $script:UpdateCount = 0
    $sourceCore = [System.IO.Path]::Combine($script:Template, 'factory', 'core')
    foreach ($name in @('FACTORY.md', 'MIGRATIONS.md', 'config.defaults.yaml')) {
        $required = Join-Path $sourceCore $name
        if (-not (Test-Path -LiteralPath $required -PathType Leaf) -or (Get-Item -LiteralPath $required).Length -eq 0) {
            Fail "The replacement core is missing $name."
        }
    }
    $staged = New-UpdateTarget (Join-ProjectPath 'factory/core')
    Copy-Item -LiteralPath $sourceCore -Destination $staged -Recurse
    Assert-StagedCopy $sourceCore $staged
    Write-Text (Join-Path $staged 'VERSION') ("$script:Version" + "`n")

    foreach ($pair in @(@('.claude', 'factory-*.md'), @('.codex', 'factory-*.toml'))) {
        $sourceDir = [System.IO.Path]::Combine($script:Template, 'root', $pair[0], 'agents')
        $targetDir = Join-ProjectPath ([System.IO.Path]::Combine($pair[0], 'agents'))
        $agents = @(Get-ChildItem -LiteralPath $sourceDir -Filter $pair[1] -File)
        if ($agents.Count -eq 0) { Fail "The replacement $($pair[0]) agents are missing." }
        foreach ($agent in $agents) {
            $staged = New-UpdateTarget (Join-Path $targetDir $agent.Name)
            Copy-Item -LiteralPath $agent.FullName -Destination $staged -Force
            Assert-StagedCopy $agent.FullName $staged
        }
        if (Test-Path -LiteralPath $targetDir) {
            foreach ($agent in (Get-ChildItem -LiteralPath $targetDir -Filter $pair[1] -File)) {
                if (-not (Test-Path -LiteralPath (Join-Path $sourceDir $agent.Name) -PathType Leaf)) {
                    $null = New-UpdateTarget $agent.FullName
                }
            }
        }
    }
    $staged = New-StagedFile (Join-ProjectPath 'factory/.models-sync-needed')
    Write-ModelsMarker $staged

    $before = Get-GitignoreState
    Set-RootFiles $script:RootMode

    $copied = 0
    $sourceRoot = [System.IO.Path]::Combine($script:Template, 'factory')
    $sourceFull = (Get-Item -LiteralPath $sourceRoot).FullName.TrimEnd('\', '/')
    $relatives = @()
    foreach ($item in (Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Force)) {
        $relative = $item.FullName.Substring($sourceFull.Length + 1) -replace '\\', '/'
        if ($relative -like 'core/*') { continue }
        $relatives += $relative
    }
    foreach ($relative in ($relatives | Sort-Object)) {
        $destination = Join-ProjectPath ('factory/' + $relative)
        if (-not (Test-Path -LiteralPath $destination)) {
            $staged = New-UpdateTarget $destination
            $source = [System.IO.Path]::Combine($sourceRoot, $relative)
            Copy-Item -LiteralPath $source -Destination $staged
            Assert-StagedCopy $source $staged
            $copied++
            Write-Info "  added missing starting file factory/$relative"
        }
    }

    Write-Info ''
    Complete-Update
    if ($before -eq 'clean' -and (Get-GitignoreState) -eq 'dirty') {
        Write-Info '  The WholeTeam block in .gitignore changed. Commit it:'
        Write-Info '    git add .gitignore && git commit -m "chore: update WholeTeam ignore rules"'
    }

    Write-Info "WholeTeam is updated to $script:Version."
    Show-RootSummary
    if ($copied -eq 0) {
        Write-Info 'No starting files were missing. Your config, state, tasks, bugs, input and output were not touched.'
    }
    Write-Info ''
    Write-Info "On your next ``Let's code``, the Orchestrator will migrate your config and state to the new version if needed."
    Write-Info "The update reset the agent files to the default models; the next ``Let's code`` re-applies the models from factory/config.yaml."
}

# --- Main ---------------------------------------------------------------------

try {
    if ($Help) { Show-Usage; exit 0 }
    if (@('', 'new', 'ongoing') -notcontains $Type) { Fail '-Type must be new or ongoing.' }
    if (@('', 'install', 'update') -notcontains $Mode) { Fail '-Mode must be install or update.' }
    $Type = $Type.ToLowerInvariant()
    $Mode = $Mode.ToLowerInvariant()

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Fail 'git was not found on PATH. Install git, then run the installer again.'
    }
    $script:ScriptDir = Get-FullPath $PSScriptRoot
    $script:Template = [System.IO.Path]::Combine($script:ScriptDir, 'template')
    $versionFile = [System.IO.Path]::Combine($script:ScriptDir, 'VERSION')
    if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf) -or -not (Test-Path -LiteralPath ([System.IO.Path]::Combine($script:Template, 'factory', 'core')) -PathType Container)) {
        Fail 'Run this script from a complete WholeTeam folder (VERSION or template/ is missing next to it).'
    }
    $script:Version = (Read-Text $versionFile).Trim()
    if ($script:Version -eq '') { Fail 'The replacement VERSION is empty.' }

    Write-Info "WholeTeam installer $script:Version"

    $raw = $Path
    if ($raw -eq '') {
        if ($Yes) { Fail '-Yes needs -Path <project>.' }
        $raw = Read-Answer 'Path to your project folder (paste it here)' ''
        if ($raw -eq '') { Fail 'No path given.' }
    }
    $script:Project = Get-NormalizedPath $raw
    if ($script:Project -eq '' -or -not (Test-Path -LiteralPath $script:Project -PathType Container)) {
        Fail "Folder not found: $($script:Project). The factory never creates project folders: create or clone your project first, then run the installer again."
    }

    $inside = Invoke-Git @('-C', $script:Project, 'rev-parse', '--is-inside-work-tree')
    if ($inside.Code -ne 0) {
        Fail 'This folder is not a git repository. Create or clone your project first, then run the installer again.'
    }
    $prefix = Invoke-Git @('-C', $script:Project, 'rev-parse', '--show-prefix')
    $prefixText = [string]($prefix.Out | Select-Object -First 1)
    if ($prefixText -ne '') {
        $topResult = Invoke-Git @('-C', $script:Project, 'rev-parse', '--show-toplevel')
        $top = Get-NormalizedPath ([string]($topResult.Out | Select-Object -First 1))
        Write-Info "This folder is inside the git repository at: $top"
        if (Confirm-Choice "WholeTeam installs at the repository top level. Use $($top)?") {
            $script:Project = $top
        } else {
            Fail "Installation cancelled. Run the installer with the repository's top-level folder."
        }
    }
    $isSelf = ($script:Project -eq $script:ScriptDir)
    if ((Test-Path -LiteralPath (Join-ProjectPath 'install.sh')) -and (Test-Path -LiteralPath (Join-ProjectPath 'template/factory/core/FACTORY.md'))) { $isSelf = $true }
    if ($isSelf) { Fail 'This is the WholeTeam folder itself. Give the path of your project instead.' }

    Restore-Update

    $installed = ''
    $coreVersion = Join-ProjectPath 'factory/core/VERSION'
    if (Test-Path -LiteralPath $coreVersion -PathType Leaf) {
        $installed = (Read-Text $coreVersion).Trim()
        $proposed = 'update'
        Write-Info "WholeTeam $installed is installed in this project; the new version is $script:Version."
    } elseif (Test-Path -LiteralPath (Join-ProjectPath 'factory')) {
        Fail "$(Join-ProjectPath 'factory') exists but is not a WholeTeam installation (factory/core/VERSION is missing). Rename or move that folder, then run the installer again."
    } else {
        $proposed = 'install'
    }

    $runMode = $Mode
    if ($runMode -eq '') {
        if ($proposed -eq 'update') {
            if (-not (Confirm-Choice "Update WholeTeam $installed -> $($script:Version)?")) { Write-Info 'Nothing changed.'; exit 0 }
        } else {
            if (-not (Confirm-Choice "Install WholeTeam $($script:Version) into $($script:Project)?")) { Write-Info 'Nothing changed.'; exit 0 }
        }
        $runMode = $proposed
    } elseif ($runMode -eq 'install' -and $proposed -eq 'update') {
        Write-Info 'WholeTeam is already installed here: running update instead, so your factory files are kept.'
        $runMode = 'update'
    } elseif ($runMode -eq 'update' -and $proposed -eq 'install') {
        Fail "WholeTeam is not installed in $($script:Project). Run the installer with -Mode install."
    }

    Initialize-OldManifest $runMode
    Test-RootFiles

    if ($runMode -eq 'install') {
        Invoke-Install
    } else {
        Invoke-Update
    }
    exit 0
} catch {
    [Console]::Error.WriteLine("Error: $($_.Exception.Message)")
    exit 1
} finally {
    if ($script:UpdateDir -ne '') {
        try { Restore-Update } catch {
            [Console]::Error.WriteLine("Error: Recovery is incomplete. Keep $script:UpdateDir and run the installer again to retry it. $($_.Exception.Message)")
        }
    }
}
