COMMUNICATEPARS - WINDOWS -> iPad/iPhone FIZIKSEL MOUSE KONTROLU
Surum: 0.3.3-universal (deneysel)

BU SURUMDE NE DEGISTI
  - Betikler artik yalnizca Intel 8087:0A2A icin degil, bilgisayardaki USB
    Bluetooth radyosunu (Intel, Broadcom, Atheros, Realtek, CSR...) kendisi bulur.
  - Yedek, kendi bilgisayarinizin aygitina gore alinir. Baska bilgisayardan
    kalma yedek otomatik algilanir ve kenara tasinir (driver-backup.eski-...).
  - Windows'un dahili (inbox) Bluetooth surucusu kullaniliyorsa ayri yedek
    gerekmez; geri yuklemede WinUSB kaldirilinca Windows kendisi geri yukler.
  - 0.3.3: Aygit tek kayit olarak bulununca "aygit bulunamadi" hatasi veren
    PowerShell 5.1 hatasi duzeltildi. 2_ dosyasi kontrol basarisiz olursa
    "yine de calistir" secenegi sunar.
  - Aygit bulma, "-like" joker karakterine degil, dogrudan kimlik karsilastirmasina
    ve Windows'un "hizmet = WinUSB" bilgisine dayanir (0.3.1'de Zadig sonrasi
    "aygit bulunamadi" hatasi veriyordu).
  - 0_DIAGNOZ.bat: bilgisayar modeli, Windows surumu ve Bluetooth USB kimligini
    diagnoz.txt dosyasina yazar.

ONEMLI UYARI
Bu yontem calisirken Bluetooth aygitinin Windows surucusunu gecici olarak WinUSB
ile degistirir. Test boyunca Windows'un normal Bluetooth ozelligi, Bluetooth
kulaklik, klavye ve mouse calismaz. Wi-Fi etkilenmez.
Baslamadan once kablolu/USB klavye ve mouse kullanin. "YEDEK HAZIR" yazisini
gormeden Zadig adimina GECMEYIN. Zadig'de yanlis aygit secmek baska bir USB
aygitini devre disi birakabilir.

GEREKSINIMLER
  - Windows 10 x64 (en az Windows 8.1; Windows 7 ile exe acilmaz)
  - USB uzerinden bagli dahili Bluetooth radyosu
  - exe, BTstack'in kendi cip surucusuyle calisir. Cipe gore durum:
      Intel     : ibt-11-5 ve ibt-12-16 yazilimlari pakette var. Baska Intel
                  modeli icin ek ibt-*.sfi/.ddc dosyasi gerekebilir.
      CSR       : genellikle ek dosya gerekmez.
      Broadcom  : yama (.hcd) dosyasi gerekebilir; bu exe icinde yok.
      Atheros   : firmware yuklemesi gerekir; bu exe icinde destek yok.
      Realtek   : firmware gerekir; bu exe icinde destek yok.
    Sony VAIO SVE1512Q1EW: USB 0489:E036 (Foxconn/Atheros AR3012 sinifi). BTstack'te
    Atheros cip destegi yoktur; Windows firmware'i zaten yuklemisse deneme
    calisabilir, calismazsa exe'nin Atheros icin ayri derlenmesi gerekir.
    Yani betikler her cipte calisir, ama exe'nin kendisi firmware gerektiren
    Broadcom/Atheros/Realtek cipleriyle calismayabilir. Bu durumda exe'nin
    yeniden derlenmesi gerekir (kaynak kod bu pakette yok).

0) (ONERILIR) DIAGNOZ
  - 0_DIAGNOZ.bat dosyasini calistirin (yonetici gerekmez).
  - Olusan diagnoz.txt dosyasindaki "Bluetooth USB radyolari" satirina bakin.

1) BLUETOOTH SURUCUSUNU YEDEKLE
  - 1_SURUCU_YEDEKLE.bat dosyasina sag tiklayin > "Yonetici olarak calistir".
  - Birden fazla aygit bulunursa bilgisayarin ICINDEKI radyoyu secin.
  - Yalnizca yesil "YEDEK HAZIR" mesajini gorurseniz devam edin. Betik ekranda
    Zadig icin "USB ID = xxxx yyyy" kimligini yazar.
  - driver-backup klasorunu test bitene kadar silmeyin veya tasimayin.

2) BLUETOOTH'U WINUSB'YE GECIR
  - Zadig'i resmi sitesinden indirin: https://zadig.akeo.ie/
  - Zadig'i yonetici olarak acin. Options > List All Devices secin.
  - Listeden YALNIZCA Bluetooth radyosunu secin; USB ID alani 1. adimda
    yazilan kimlikle BIREBIR ayni olmali.
  - Sagda WinUSB secin > Replace Driver > bitmesini bekleyin.
  - Wi-Fi, mouse, klavye veya kamerayi secmeyin.

3) FIZIKSEL MOUSE KONTROLUNU CALISTIR
  - 2_MOUSE_KONTROLUNU_CALISTIR.bat dosyasini acin.
  - Konsolda "Windows Raw Input hazir" ve "BTstack up and running" yazilarini
    bekleyin.
  - iPad/iPhone'da Bluetooth ve AssistiveTouch'u acin.
  - Ayarlar > Erisilebilirlik > Dokunma > AssistiveTouch > Aygitlar >
    Bluetooth Aygitlari bolumunden "HID Mouse" aygitini baglayin.
  - Konsolda "Report Characteristic Subscribed 1" gorulunce K tusuna basin.

KONTROLLER
  K       : Fiziksel mouse'u iPad'e verir.
  K tekrar: Mouse'u Windows'a geri verir.
  Ctrl+C  : Programi kapatir.

4) WINDOWS BLUETOOTH'U GERI GETIR
  - K ile mouse'u Windows'a geri alin, Ctrl+C ile kapatin.
  - 3_BLUETOOTHU_GERI_GETIR.bat > "Yonetici olarak calistir".
  - "BLUETOOTH GERI YUKLENDI" mesajini bekleyin. Simge gelmezse bir kez yeniden
    baslatin.

SORUN CIKARSA
  - 0_DIAGNOZ.bat ciktisini (diagnoz.txt) ve exe konsolunun ekran goruntusunu alin.
  - Geri yukleme olmazsa: Windows'u yeniden baslatip 3_ dosyasini tekrar
    calistirin. Yine olmazsa Aygit Yoneticisi > Bluetooth aygiti > Surucuyu
    Guncelle > Bilgisayarimda surucu ara > Listeden sec ile asil surucuyu secin.

LISANS
BTstack sadece kisisel ve ticari olmayan kullanim kosuluyla bu pakette bulunur.
Ticari kullanim icin BlueKitchen ticari lisansi gerekir. Ayrintilar licenses
klasorundedir.

PROGRAM SHA-256
  CommunicatePars-iOS-Mouse.exe
  33220a6ff8ad14cf3992231a56c8d9976447ba54152b1193a32d1289af357394
