#requires -Version 5.1
. (Join-Path $PSScriptRoot 'Common.ps1')

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'diagnoz.txt'
$lines = New-Object System.Collections.Generic.List[string]

function Add-Line([string]$t) { $lines.Add($t) | Out-Null; Write-Host $t }

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
Add-Line ('Bilgisayar : {0} {1}' -f $cs.Manufacturer, $cs.Model)
Add-Line ('Windows    : {0} (surum {1}, build {2}, {3})' -f $os.Caption, $os.Version, $os.BuildNumber, $os.OSArchitecture)
Add-Line ('Yonetici   : {0}' -f (Test-Administrator))
if ([int]$os.BuildNumber -lt 9600) {
    Add-Line 'UYARI: Windows 8.1 (build 9600) altinda exe WinUSB ISOCHRONOUS islevlerini bulamaz ve acilmaz. Windows 10 gerekir.'
}
Add-Line ''

Add-Line '--- Bluetooth USB radyolari ---'
$radios = @(Get-BluetoothRadios)
if ($radios.Count -eq 0) { Add-Line 'BULUNAMADI (dahili Bluetooth USB uzerinden bagli degil ya da kapali olabilir)' }
foreach ($r in $radios) {
    Add-Line ('{0}  USB {1}:{2}' -f $r.Name, $r.VendorId, $r.ProductId)
    Add-Line ('   DeviceID : {0}' -f $r.DeviceID)
    Add-Line ('   Surucu   : {0} / {1} / {2}' -f $r.InfName, $r.Provider, $r.Version)
    $st = @(Get-DriversForUsbId $r.VendorId $r.ProductId)
    foreach ($x in $st) { Add-Line ('   Kayit    : {0} | hizmet: {1} | WinUSB: {2}' -f $x.DeviceID, $x.Service, $x.IsWinUsb) }
    if ($script:KnownChips.ContainsKey($r.VendorId)) { Add-Line ('   Not      : ' + $script:KnownChips[$r.VendorId]) }
}
Add-Line ''

Add-Line '--- Tum USB aygitlari (ozet) ---'
Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -like 'USB\VID_*' -and $_.DeviceID -notmatch '&MI_' } |
    ForEach-Object { Add-Line ('{0} | {1} | {2}' -f $_.DeviceID, $_.Name, $_.PNPClass) }
Add-Line ''

Add-Line '--- Paket dosyalari ---'
Get-ChildItem -Path $root -Filter 'ibt-*' -File | ForEach-Object { Add-Line ('{0} ({1} bayt)' -f $_.Name, $_.Length) }
Add-Line ('Yedek var mi: {0}' -f (Test-Path (Join-Path $root 'driver-backup\BACKUP_OK.txt')))

$lines | Out-File $out -Encoding utf8
Write-Host ''
Write-Host "Bu bilgiler su dosyaya da yazildi: $out" -ForegroundColor Green
