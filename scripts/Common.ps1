# Ortak fonksiyonlar - tum betikler tarafindan kullanilir (ASCII, PowerShell 5.1)

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WinUsbProvider([string]$Provider) {
    return ($Provider -match 'libwdi|WinUSB')
}

# Bilgisayardaki USB Bluetooth radyolarini bulur (marka/model bagimsiz).
function Get-BluetoothRadios {
    $signed = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        Where-Object { $_.DeviceID -like 'USB\VID_*' })
    $entities = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object { $_.DeviceID -like 'USB\VID_*' })

    $found = @{}
    $result = @()
    foreach ($e in $entities) {
        if ($e.DeviceID -notmatch '^USB\\VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})') { continue }
        $vendorId = $Matches[1].ToUpper()
        $productId = $Matches[2].ToUpper()

        $ids = @()
        if ($e.CompatibleID) { $ids += $e.CompatibleID }
        if ($e.HardwareID) { $ids += $e.HardwareID }
        $classMatch = @($ids | Where-Object { $_ -match 'Class_E0&SubClass_01&Prot_01' }).Count -gt 0
        $isBluetooth = ($e.PNPClass -eq 'Bluetooth') -or $classMatch -or ([string]$e.Name -match 'Bluetooth')
        if (-not $isBluetooth) { continue }

        $key = $vendorId + ':' + $productId
        if ($found.ContainsKey($key)) { continue }
        $found[$key] = $true

        $drv = $signed | Where-Object { $_.DeviceID -eq $e.DeviceID } | Select-Object -First 1
        $result += [pscustomobject]@{
            VendorId     = $vendorId
            ProductId    = $productId
            Name         = [string]$e.Name
            DeviceID     = [string]$e.DeviceID
            InfName      = $(if ($drv) { [string]$drv.InfName } else { '' })
            Provider     = $(if ($drv) { [string]$drv.DriverProviderName } else { '' })
            Version      = $(if ($drv) { [string]$drv.DriverVersion } else { '' })
            Manufacturer = $(if ($drv) { [string]$drv.Manufacturer } else { '' })
        }
    }
    return $result
}

# Belirli VID/PID icin aygit + surucu kayitlarini dondurur.
# Joker karakter (-like) kullanmaz; once Win32_PnPEntity ile aygidin varligini,
# sonra Win32_PnPSignedDriver ve Service alani ile WinUSB durumunu belirler.
function Get-DriversForUsbId([string]$VendorId, [string]$ProductId) {
    $prefix = ('USB\VID_' + $VendorId + '&PID_' + $ProductId).ToUpper()

    $entities = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object { ([string]$_.DeviceID).ToUpper().StartsWith($prefix) })
    $signed = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        Where-Object { ([string]$_.DeviceID).ToUpper().StartsWith($prefix) })

    $records = @()
    foreach ($e in $entities) {
        $s = $signed | Where-Object { $_.DeviceID -eq $e.DeviceID } | Select-Object -First 1
        $provider = ''
        $inf = ''
        $version = ''
        if ($s) {
            $provider = [string]$s.DriverProviderName
            $inf = [string]$s.InfName
            $version = [string]$s.DriverVersion
        }
        $service = [string]$e.Service
        $isWinUsb = (Test-WinUsbProvider $provider) -or ($service -eq 'WinUSB')
        $records += [pscustomobject]@{
            DeviceID           = [string]$e.DeviceID
            InfName            = $inf
            DriverProviderName = $provider
            DriverVersion      = $version
            Service            = $service
            IsWinUsb           = $isWinUsb
        }
    }
    return ,@($records)
}

# Hata ayiklama: sistemdeki tum USB VID kayitlarini yazar.
function Write-UsbDeviceList {
    Write-Host 'Sistemde gorunen USB aygitlari:' -ForegroundColor Yellow
    Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
        Where-Object { $_.DeviceID -like 'USB\VID_*' -and $_.DeviceID -notmatch '&MI_' } |
        ForEach-Object { Write-Host ('  {0} | {1} | hizmet: {2}' -f $_.DeviceID, $_.Name, $_.Service) }
}

function Select-BluetoothRadio {
    param([array]$Radios, [string]$PreferVendorId, [string]$PreferProductId)

    if ($PreferVendorId) {
        $match = @($Radios | Where-Object { $_.VendorId -eq $PreferVendorId -and $_.ProductId -eq $PreferProductId })
        if ($match.Count -ge 1) { return $match[0] }
    }
    if ($Radios.Count -eq 1) { return $Radios[0] }

    Write-Host 'Birden fazla Bluetooth USB aygiti bulundu:' -ForegroundColor Yellow
    for ($i = 0; $i -lt $Radios.Count; $i++) {
        $r = $Radios[$i]
        Write-Host ('  [{0}] {1}  USB {2}:{3}  surucu: {4}' -f ($i + 1), $r.Name, $r.VendorId, $r.ProductId, $r.Provider)
    }
    Write-Host 'Bilgisayarin ICINDE gomulu olan Bluetooth radyosunu secin.'
    $choice = Read-Host 'Numara'
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $Radios.Count) {
        Write-Host 'HATA: Gecersiz secim.' -ForegroundColor Red
        exit 20
    }
    return $Radios[$index - 1]
}

# Kaydedilmis radyo bilgisini okur (eski 0.3.0 yedeklerini de tanir).
function Read-RadioInfo([string]$BackupDir) {
    $radioFile = Join-Path $BackupDir 'radio.json'
    if (Test-Path $radioFile) {
        return (Get-Content $radioFile -Raw | ConvertFrom-Json)
    }
    $idFile = Join-Path $BackupDir 'device-id.txt'
    $infFile = Join-Path $BackupDir 'original-inf.txt'
    if ((Test-Path $idFile) -and (Test-Path $infFile)) {
        $deviceId = (Get-Content $idFile -Raw).Trim()
        if ($deviceId -match '^USB\\VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})') {
            return [pscustomobject]@{
                VendorId        = $Matches[1].ToUpper()
                ProductId       = $Matches[2].ToUpper()
                DeviceID        = $deviceId
                OriginalInfName = (Get-Content $infFile -Raw).Trim()
                Mode            = 'oem'
            }
        }
    }
    return $null
}

$script:KnownChips = @{
    '8087' = 'Intel: bu pakette ibt-11-5 ve ibt-12-16 yazilimi var; baska Intel modeli ek ibt-*.sfi dosyasi isteyebilir.'
    '0A5C' = 'Broadcom: BTstack icin .hcd yama dosyasi gerekebilir; cip ROM ile acilmissa calisabilir.'
    '0CF3' = 'Qualcomm Atheros: firmware yuklemesi gerekir; bu exe desteklemiyor olabilir.'
    '13D3' = 'Atheros / Azurewave: firmware yuklemesi gerekebilir.'
    '04CA' = 'Atheros / Lite-On: firmware yuklemesi gerekebilir.'
    '0489' = 'Foxconn / Atheros: firmware yuklemesi gerekebilir.'
    '0BDA' = 'Realtek: firmware (rtl_bt) gerekebilir.'
    '0A12' = 'CSR: genellikle ek firmware gerektirmez.'
}
