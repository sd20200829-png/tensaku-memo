param([string]$MdPath)
if (-not $MdPath -or -not (Test-Path $MdPath)) {
    Write-Host "Error: file not found - $MdPath"
    pause
    exit 1
}

$scriptDir = $PSScriptRoot
$toolPath = Join-Path $scriptDir "tensaku-memo.html"
if (-not (Test-Path $toolPath)) {
    Write-Host "Error: tensaku-memo.html not found in $scriptDir"
    pause
    exit 1
}

# Read source files
$toolHtml = [System.IO.File]::ReadAllText($toolPath, [System.Text.Encoding]::UTF8)
$mdBytes  = [System.IO.File]::ReadAllBytes((Resolve-Path $MdPath).Path)
$mdBase64 = [System.Convert]::ToBase64String($mdBytes)
$mdName   = [System.IO.Path]::GetFileName($MdPath)
$mdNameSafe = $mdName.Replace('\','\').Replace("'","\'")

# Build auto-load script (single-quoted here-string = no PS variable expansion)
$autoLoad = @'
<script>
(function(){
  try {
    var b = atob('__B64__');
    var a = new Uint8Array(b.length);
    for(var i=0;i<b.length;i++) a[i]=b.charCodeAt(i);
    var text = new TextDecoder('utf-8').decode(a);
    loadContent(text, '__NAME__');
  } catch(e) { console.error('Auto-load failed:', e); alert('Auto-load failed: ' + e.message); }
})();
</script>
'@

$autoLoad = $autoLoad.Replace('__B64__', $mdBase64).Replace('__NAME__', $mdNameSafe)

# Inject before </body> and write temp HTML
$output = $toolHtml.Replace('</body>', "$autoLoad`n</body>")
$tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "tensaku-memo-session.html"
[System.IO.File]::WriteAllText($tempPath, $output, [System.Text.Encoding]::UTF8)

# Open in Edge: right side, ~45% screen width, stay within screen bounds
try {
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $w = [int]($screen.Width * 0.45)
    $h = [int]($screen.Height - 40)
    $x = [int]($screen.Left + $screen.Width - $w - 16)
    $y = [int]($screen.Top)
    Start-Process "msedge" -ArgumentList "--new-window", "--window-size=$w,$h", "--window-position=$x,$y", "`"$tempPath`""
} catch {
    # Fallback: open with default browser
    Start-Process $tempPath
}
