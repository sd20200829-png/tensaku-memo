[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$cmdPath = Join-Path $PSScriptRoot 'open-tensaku.cmd'
$commandValue = "`"$cmdPath`" `"%1`""

# Two registration locations for best compatibility
$regKeys = @(
    'HKCU:\Software\Classes\.md\shell\TensakuMemo',
    'HKCU:\Software\Classes\SystemFileAssociations\.md\shell\TensakuMemo'
)

try {
    Write-Host ''
    Write-Host '=== 添削メモツール: 右クリックメニュー設定 ===' -ForegroundColor Cyan
    Write-Host ''

    $installed = $regKeys | Where-Object { Test-Path $_ }

    if ($installed.Count -gt 0) {
        Write-Host '[現在] メニュー登録済み' -ForegroundColor Yellow
        Write-Host ''
        $choice = Read-Host 'アンインストールしますか？ (y/N)'
        if ($choice -eq 'y') {
            foreach ($key in $regKeys) {
                if (Test-Path $key) { Remove-Item -Path $key -Recurse -Force }
            }
            Write-Host '[完了] 右クリックメニューから削除しました。' -ForegroundColor Green
        } else {
            Write-Host '変更なし。'
        }
    } else {
        Write-Host "登録先: $cmdPath"
        Write-Host ''
        foreach ($key in $regKeys) {
            New-Item -Path $key -Force | Out-Null
            Set-ItemProperty -Path $key -Name '(Default)' -Value '添削メモで開く'
            Set-ItemProperty -Path $key -Name 'Position' -Value 'Top'
            New-Item -Path "$key\command" -Force | Out-Null
            Set-ItemProperty -Path "$key\command" -Name '(Default)' -Value $commandValue
        }
        Write-Host '[完了] 右クリックメニューに「添削メモで開く」を追加しました。' -ForegroundColor Green
        Write-Host ''
        Write-Host 'Win11: 右クリック → 「その他のオプションを確認」→ 上部に表示されます。'
        Write-Host '  ヒント: Shift + 右クリック で直接クラシックメニューを開けます。'
    }
} catch {
    Write-Host ''
    Write-Host "[エラー] $_" -ForegroundColor Red
}

Write-Host ''
Read-Host '終了するにはEnterを押してください'
