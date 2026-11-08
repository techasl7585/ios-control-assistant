@echo off
chcp 65001 >nul
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Check-WinUSB.ps1"
if errorlevel 1 (
    echo.
    echo Kontrol basarisiz oldu. Yukaridaki mesaji okuyun.
    echo Aygit Zadig ile WinUSB'ye gecirildiyse yine de denemek isterseniz E'ye basin.
    choice /c EH /n /m "Yine de exe calistirilsin mi? [E/H]: "
    if errorlevel 2 exit /b 1
)

echo.
echo CommunicatePars fiziksel mouse kontrolu basliyor.
echo   K       = mouse'u iPad'e ver / Windows'a geri al
echo   Ctrl+C  = programi kapat
echo.
CommunicatePars-iOS-Mouse.exe

echo.
echo ONEMLI: Normal Windows Bluetooth'u geri almak icin
echo 3_BLUETOOTHU_GERI_GETIR.bat dosyasini yonetici olarak calistirin.
pause
