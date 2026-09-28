param([switch]$Editor)
$ErrorActionPreference = 'Stop'
try {
    $projectFolder = Split-Path -Parent $PSScriptRoot
    if (!(Test-Path -LiteralPath (Join-Path $projectFolder 'project.godot'))) {
        throw 'Extract the complete ZIP before using this launcher.'
    }
    $settingsFolder = Join-Path $env:LOCALAPPDATA 'VanguardMapPlaytest'
    $savedPath = Join-Path $settingsFolder 'godot-path.txt'
    $godotExecutable = $null
    $candidates = @()
    if ($env:GODOT4_BIN) { $candidates += $env:GODOT4_BIN }
    if (Test-Path -LiteralPath $savedPath) { $candidates += (Get-Content -LiteralPath $savedPath -Raw).Trim() }
    foreach ($name in @('godot4.exe', 'godot.exe')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
        if ($command) { $candidates += $command.Source }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $godotExecutable = $candidate; break }
    }
    if (!$godotExecutable) {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Select your installed Godot 4 executable'
        $picker.Filter = 'Godot executable (*.exe)|*.exe'
        $picker.CheckFileExists = $true
        if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
        $godotExecutable = $picker.FileName
        $picker.Dispose()
    }
    $version = (& $godotExecutable --version | Out-String).Trim()
    if ($version -notmatch '^4\.(\d+)\.') { throw 'Choose a Godot 4 executable. Godot 3 cannot open this project.' }
    if ([int]$Matches[1] -lt 4) { throw 'This project requires Godot 4.4 or newer.' }
    New-Item -ItemType Directory -Path $settingsFolder -Force | Out-Null
    Set-Content -LiteralPath $savedPath -Value $godotExecutable -Encoding UTF8
    # Import resources before direct play, including when this is a freshly extracted ZIP.
    Write-Host 'Preparing Havenreach assets...'
    & $godotExecutable --headless --editor --path $projectFolder --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot asset import failed. See the message above.' }
    $arguments = @('--path', ('"' + $projectFolder + '"'))
    if ($Editor) { $arguments += '--editor' }
    Start-Process -FilePath $godotExecutable -ArgumentList $arguments -WorkingDirectory $projectFolder
} catch {
    Write-Host ('Havenreach launcher: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'You can also import project.godot manually in the Godot Project Manager.'
    exit 1
}
