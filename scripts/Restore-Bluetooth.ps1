#requires -Version 5.1
. (Join-Path $PSScriptRoot 'Common.ps1')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupDir = Join-Path $root 'driver-backup'
$readyMarker = Join-Path $backupDir 'BACKUP_OK.txt'

if (-not (Test-Administrator)) {
    Write-Host 'HATA: Bu dosya yonetici yetkisiyle calistirilmali.' -ForegroundColor Red
    Write-Host '3_BLUETOOTHU_GERI_GETIR.bat dosyasina sag tiklayip "Yonetici olarak calistir" secin.'
    exit 1
}

if (-not (Test-Path $readyMarker)) {
    Write-Host 'HATA: Dogrulanmis surucu yedegi yok; otomatik geri yukleme yapilmadi.' -ForegroundColor Red
    exit 2
}

$info = Read-RadioInfo $backupDir
if ($null -eq $info) {
    Write-Host 'HATA: Yedek bilgisi gecersiz; otomatik islem yapilmadi.' -ForegroundColor Red
    exit 3
}

$vendorId = [string]$info.VendorId
$productId = [string]$info.ProductId
$mode = [string]$info.Mode
if (-not $mode) { $mode = 'oem' }

$drivers = @(Get-DriversForUsbId $vendorId $productId)
if ($drivers.Count -lt 1) {
    Write-Host ('HATA: USB {0}:{1} aygiti bulunamadi.' -f $vendorId, $productId) -ForegroundColor Red
    Write-UsbDeviceList
    exit 3
}

$winusb = @($drivers | Where-Object { $_.IsWinUsb })
if ($winusb.Count -eq 0) {
    Write-Host 'Bluetooth zaten WinUSB disinda bir surucu kullaniyor.' -ForegroundColor Green
    Write-Host ('Surucu: {0} / {1}' -f $drivers[0].InfName, $drivers[0].DriverProviderName)
    exit 0
}

$winusbInfs = @($winusb | ForEach-Object { [string]$_.InfName } | Where-Object { $_ -match '^oem\d+\.inf$' } | Sort-Object -Unique)
if ($winusbInfs.Count -lt 1) {
    Write-Host 'HATA: Kaldirilacak WinUSB paketi beklenen bicimde degil. Guvenlik icin hicbir surucu silinmedi.' -ForegroundColor Red
    exit 4
}

foreach ($inf in $winusbInfs) {
    Write-Host "Gecici WinUSB surucusu kaldiriliyor: $inf"
    & pnputil.exe /delete-driver $inf /uninstall /force
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'HATA: WinUSB surucusu kaldirilamadi. Bilgisayari yeniden baslatip tekrar deneyin.' -ForegroundColor Red
        exit 5
    }
}

if ($mode -eq 'oem') {
    $backupInfs = @(Get-ChildItem -Path $backupDir -Recurse -Filter '*.inf' -File)
    Write-Host 'Yedek Bluetooth surucusu yukleniyor...'
    foreach ($inf in $backupInfs) {
        & pnputil.exe /add-driver $inf.FullName /install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "UYARI: Bu INF yuklenemedi: $($inf.FullName)" -ForegroundColor Yellow
        }
    }
}

& pnputil.exe /scan-devices | Out-Host
Start-Sleep -Seconds 3

$after = @(Get-DriversForUsbId $vendorId $productId)
$stillWinUsb = @($after | Where-Object { $_.IsWinUsb })

if ($after.Count -ge 1 -and $stillWinUsb.Count -eq 0) {
    Write-Host ''
    Write-Host 'BLUETOOTH GERI YUKLENDI' -ForegroundColor Green
    Write-Host ('Surucu: {0} / {1} / {2}' -f $after[0].InfName, $after[0].DriverProviderName, $after[0].DriverVersion)
    Write-Host 'Bluetooth simgesi hemen gelmezse Windows''u bir kez yeniden baslatin.'
    exit 0
}

Write-Host ''
Write-Host 'Geri yukleme tamamlanamadi.' -ForegroundColor Red
Write-Host 'Bilgisayari yeniden baslatin ve bu dosyayi bir kez daha yonetici olarak calistirin.'
Write-Host 'Olmazsa: Aygit Yoneticisi > aygit > Surucuyu Guncelle > Bilgisayarimda surucu ara > Listeden sec.'
Write-Host "Yedek klasoru: $backupDir"
exit 6
