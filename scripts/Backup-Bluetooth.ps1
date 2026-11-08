#requires -Version 5.1
. (Join-Path $PSScriptRoot 'Common.ps1')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupDir = Join-Path $root 'driver-backup'
$readyMarker = Join-Path $backupDir 'BACKUP_OK.txt'
$radioFile = Join-Path $backupDir 'radio.json'

if (-not (Test-Administrator)) {
    Write-Host 'HATA: Bu dosya yonetici yetkisiyle calistirilmali.' -ForegroundColor Red
    Write-Host '1_SURUCU_YEDEKLE.bat dosyasina sag tiklayip "Yonetici olarak calistir" secin.'
    exit 1
}

$radios = @(Get-BluetoothRadios)
if ($radios.Count -eq 0) {
    Write-Host 'HATA: USB Bluetooth radyosu bulunamadi.' -ForegroundColor Red
    Write-Host 'Aygit Yoneticisi > Bluetooth bolumunde bir aygit gorunuyor mu kontrol edin.'
    Write-Host 'Bilgi toplamak icin 0_DIAGNOZ.bat dosyasini calistirip diagnoz.txt dosyasini paylasin.'
    Write-Host 'Zadig ile hicbir surucuyu degistirmeyin.'
    exit 2
}

$existing = Read-RadioInfo $backupDir
$preferVid = $null; $preferPid = $null
if ($existing) { $preferVid = [string]$existing.VendorId; $preferPid = [string]$existing.ProductId }

$radio = Select-BluetoothRadio -Radios $radios -PreferVendorId $preferVid -PreferProductId $preferPid

# Mevcut yedek bu bilgisayardaki radyoyla uyumlu mu?
if ($existing -and (Test-Path $readyMarker) -and
    [string]$existing.VendorId -eq $radio.VendorId -and [string]$existing.ProductId -eq $radio.ProductId) {

    if (-not (Test-Path $radioFile)) {
        # Eski (0.3.0) yedek: yeni bilgi dosyasini tamamla
        $existing | ConvertTo-Json | Out-File $radioFile -Encoding utf8
    }
    Write-Host 'YEDEK HAZIR: Daha once olusturulmus ve bu aygitla uyumlu.' -ForegroundColor Green
    Write-Host ('Aygit: USB {0}:{1}' -f $radio.VendorId, $radio.ProductId)
    Write-Host "Konum: $backupDir"
    exit 0
}

# Baska bilgisayardan kalma / uyumsuz yedek: kenara al
if (Test-Path $backupDir) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $oldDir = Join-Path $root ('driver-backup.eski-' + $stamp)
    Write-Host 'UYARI: Mevcut yedek bu bilgisayardaki Bluetooth aygitina ait degil.' -ForegroundColor Yellow
    Write-Host "Eski yedek tasiniyor: $oldDir"
    Move-Item $backupDir $oldDir
}

if (Test-WinUsbProvider $radio.Provider) {
    Write-Host 'HATA: Bu Bluetooth aygiti zaten WinUSB kullaniyor ve gecerli bir yedek yok.' -ForegroundColor Red
    Write-Host 'Aygit Yoneticisi > aygit > Surucuyu Guncelle > Bilgisayarimda surucu ara >'
    Write-Host 'Kullanilabilir suruculer listesinden sec... yolu ile asil Bluetooth surucusunu secin,'
    Write-Host 'ya da Windows Update / uretici surucusunu yeniden yukleyin; sonra bu dosyayi tekrar calistirin.'
    exit 3
}

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$mode = 'inbox'
if ($radio.InfName -match '^oem\d+\.inf$') { $mode = 'oem' }

$metadata = [ordered]@{
    BackupTimeUtc   = (Get-Date).ToUniversalTime().ToString('o')
    VendorId        = $radio.VendorId
    ProductId       = $radio.ProductId
    DeviceName      = $radio.Name
    DeviceID        = $radio.DeviceID
    Manufacturer    = $radio.Manufacturer
    DriverProvider  = $radio.Provider
    DriverVersion   = $radio.Version
    OriginalInfName = $radio.InfName
    Mode            = $mode
}
$metadata | ConvertTo-Json | Out-File $radioFile -Encoding utf8
$radio.InfName | Out-File (Join-Path $backupDir 'original-inf.txt') -Encoding ascii
$radio.DeviceID | Out-File (Join-Path $backupDir 'device-id.txt') -Encoding ascii

Write-Host ('Aygit : {0}  (USB {1}:{2})' -f $radio.Name, $radio.VendorId, $radio.ProductId)
Write-Host ('Surucu: {0} / {1} / {2}' -f $radio.InfName, $radio.Provider, $radio.Version)

if ($mode -eq 'oem') {
    Write-Host ' Ucuncu taraf surucu yedekleniyor...'
    & pnputil.exe /export-driver $radio.InfName $backupDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'HATA: pnputil surucu paketini disari aktaramadi.' -ForegroundColor Red
        Write-Host 'Zadig ile hicbir surucuyu degistirmeyin.'
        Remove-Item $readyMarker -ErrorAction SilentlyContinue
        exit 4
    }
    $exportedInf = @(Get-ChildItem -Path $backupDir -Recurse -Filter '*.inf' -File)
    if ($exportedInf.Count -lt 1) {
        Write-Host 'HATA: Yedek klasorunde INF dosyasi bulunamadi.' -ForegroundColor Red
        Write-Host 'Zadig ile hicbir surucuyu degistirmeyin.'
        exit 5
    }
} else {
    Write-Host 'Bu aygit Windows''un dahili (inbox) surucusunu kullaniyor; ayri yedek gerekmiyor.' -ForegroundColor Cyan
    Write-Host 'Geri yukleme sirasinda WinUSB kaldirilinca Windows dahili surucuyu kendisi geri yukler.'
}

@(
    'CommunicatePars Bluetooth driver backup is complete.'
    "Mode: $mode"
    "Device ID: $($radio.DeviceID)"
) | Out-File $readyMarker -Encoding ascii

Write-Host ''
Write-Host 'YEDEK HAZIR' -ForegroundColor Green
Write-Host ''
Write-Host 'ZADIG ADIMI ICIN KIMLIK (bunu birebir kontrol edin):' -ForegroundColor Cyan
Write-Host ('   USB ID = {0} {1}' -f $radio.VendorId, $radio.ProductId) -ForegroundColor Cyan
Write-Host ''
Write-Host 'Yalnizca bu mesaj gorulduyse README dosyasindaki Zadig adimina gecebilirsiniz.'
exit 0
