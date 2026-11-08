#requires -Version 5.1
. (Join-Path $PSScriptRoot 'Common.ps1')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupDir = Join-Path $root 'driver-backup'
$readyMarker = Join-Path $backupDir 'BACKUP_OK.txt'

if (-not (Test-Path $readyMarker)) {
    Write-Host 'HATA: Dogrulanmis Bluetooth surucu yedegi yok.' -ForegroundColor Red
    Write-Host 'Once 1_SURUCU_YEDEKLE.bat dosyasini yonetici olarak calistirin.'
    exit 1
}

$info = Read-RadioInfo $backupDir
if ($null -eq $info) {
    Write-Host 'HATA: Yedek bilgisi okunamadi (radio.json yok). 1_SURUCU_YEDEKLE.bat dosyasini tekrar calistirin.' -ForegroundColor Red
    exit 2
}

$vendorId = [string]$info.VendorId
$productId = [string]$info.ProductId
$drivers = @(Get-DriversForUsbId $vendorId $productId)

if ($drivers.Count -lt 1) {
    Write-Host ('HATA: USB {0}:{1} aygiti bulunamadi. Aygit takili ve acik mi?' -f $vendorId, $productId) -ForegroundColor Red
    Write-Host 'Yedek baska bir bilgisayardan kalmis olabilir: driver-backup klasorunu silip 1_SURUCU_YEDEKLE.bat calistirin.'
    Write-UsbDeviceList
    exit 3
}

$winusb = @($drivers | Where-Object { $_.IsWinUsb })
if ($winusb.Count -lt 1) {
    Write-Host 'HATA: Bluetooth aygiti henuz WinUSB kullanmiyor.' -ForegroundColor Red
    Write-Host ('Mevcut saglayici: {0} / hizmet: {1}' -f $drivers[0].DriverProviderName, $drivers[0].Service)
    Write-Host ('Zadig''de YALNIZCA USB ID {0} {1} olan aygiti secip WinUSB yukleyin.' -f $vendorId, $productId)
    exit 4
}

if ($vendorId -eq '8087') {
    $fw = @(Get-ChildItem -Path $root -Filter 'ibt-*.sfi' -File -ErrorAction SilentlyContinue)
    if ($fw.Count -lt 1) {
        Write-Host 'HATA: Intel firmware dosyalari (ibt-*.sfi) eksik.' -ForegroundColor Red
        exit 5
    }
} elseif ($script:KnownChips.ContainsKey($vendorId)) {
    Write-Host ('NOT: ' + $script:KnownChips[$vendorId]) -ForegroundColor Yellow
}

Write-Host 'WinUSB ve surucu yedegi dogrulandi.' -ForegroundColor Green
Write-Host ('Aygit: USB {0}:{1}' -f $vendorId, $productId)
Write-Host ('Surucu: {0} / {1} / hizmet: {2}' -f $winusb[0].InfName, $winusb[0].DriverProviderName, $winusb[0].Service)
exit 0
