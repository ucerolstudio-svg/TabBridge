# TabBridge

**Galaxy Tab’ı Mac’in ikinci ekranı yap — USB veya Wi-Fi, S Pen ve küçük Mac widget’ı.**

TabBridge, [OpenDisplay](https://github.com/peetzweg/opendisplay) temel alınarak geliştirilen bağımsız, **GPL-3.0** lisanslı bir projedir. Ekran aktarım motoru ve Android alıcısı üst projeden gelir. Basit Mac arayüzü, Android USB kurulum/bağlantı yönetimi ve küçük WidgetKit widget’ı bu projenin eklemeleridir. Üst projenin yazar ve lisans bildirimleri korunur.

> **Deneysel geliştirme sürümü.** Yerel test: Apple Silicon Mac/macOS 26.6 ve Galaxy Tab S8 Ultra SM-X906B/Android 16. Her cihazda çalışma, sıfır hata veya Apple Sidecar’ın bütün özellikleriyle eşdeğerlik iddiası yoktur.

[İndir](https://github.com/ucerolstudio-svg/TabBridge/releases) · [Adım adım kurulum](Native/README.md) · [Test sonuçları](Native/VALIDATION.md) · [Lisans](LICENSE)

## İlk kurulum

1. Releases bölümünden **macos-arm64.zip** dosyasını indir, aç ve **TabBridge.app** uygulamasını Uygulamalar klasörüne taşı.
2. Uygulamayı aç. **Ekran Kaydı** ve **Erişilebilirlik** izinlerini ver. macOS isterse uygulamayı kapatıp yeniden aç. Paket yerel ad hoc imzalıdır; Apple noter onayı henüz yoktur.
3. Tableti USB **veri** kablosuyla bağla. Geliştirici seçenekleri → **USB hata ayıklama** seçeneğini aç ve tablette kendi Mac’ine izin ver.
4. Mac’te **Tableti bul → Tablete kur** seç. Android APK Mac paketine dahildir; ayrı APK da Releases bölümündedir.
5. **Kablolu** seç. Kablosuz kullanım için tablette TabBridge açıkken aynı Wi-Fi ağına bağlanıp **Kablosuz** seç.
6. Küçük widget: masaüstüne sağ tık → **Widget’ları Düzenle → TabBridge**. Sonraki bağlantıları **Kablolu / Kablosuz** düğmelerinden başlat.

Samsung Otomatik Engelleyici, USB hata ayıklamayı engelleyebilir. Güvenlik etkileri, gri anahtar, Mac izin sorunları ve derleme adımları [tam rehberde](Native/README.md) açıklanır.

## Kullanım

- **Gerçek ikinci ekran:** Mac pencerelerini tablete sürükle.
- **Sağ/sol/üst konum:** TabBridge → Ekranların konumunu ayarla → Düzenle. Tablet kutusunu MacBook’un istediğin kenarına taşı. Fransızca macOS: *Moniteurs → Organiser… → Terminé*.
- **Kalem:** S Pen ile tıkla ve sürükle; iki parmakla kaydır. Basınç/eğim iletimi kodda vardır; çizim uygulamalarında doğruluğu henüz doğrulanmadı.
- **Bağlantı değişimi:** Widget’tan modu seç. Kabloyu çıkarmak kendiliğinden Wi-Fi’ye geçiş başlatmaz.
- **Bitir:** Uygulamada Bağlantıyı kes veya menü çubuğunda Çıkış.

## Doğrulananlar ve sınırlar

35 Android testi, Android lint ve 8 Mac USB seçim testi geçti. Gerçek USB/Wi-Fi genişletilmiş ekran, iki widget bağlantısının görüntüyü başlatması ve S Pen tıklama/sürükleme doğrulandı. [Test kapsamı](Native/VALIDATION.md).

**Wi-Fi geliştirme protokolünde eşleştirme kodu ve taşıma şifrelemesi yoktur. Yalnızca güvendiğin özel yerel ağında kullan.** Bu eksik giderilmeden genel kullanıma hazır bir güvenli eşleştirme sistemi sayılmaz.

Aktif aktarım Mac ve tabletin pil tüketimini artırır; uzun süreli pil ölçümü yapılmadı. Donanım video kodlama/çözme kullanılır. Kalıcı sistem sürücüsü kurulmaz; geçici sanal ekran ve ScreenCaptureKit kullanılır. Sanal ekranın özel macOS API’si gelecekteki sistem sürümlerinde uyumluluk riski taşır. Uyku/uyanma, uzun oturumlar ve başka modeller ayrıca denenmelidir.

## Geliştirme ve lisans

[Kaynaktan derleme ve test komutları](Native/README.md#kaynaktan-derleme). Mac için Native derleme betiğini kullan. Üst projenin özgün hedefleri ve [README’si](README-OpenDisplay.md) kaynakta korunmuştur; bunların bütün platform iddiaları TabBridge için test edilmiş değildir.

**GPL-3.0.** Yazılım garanti verilmeden sunulur. Dağıtırken karşılık gelen kaynak ve lisans bildirimlerini koru. [Hukuki bildirim](LEGAL.md), [gizlilik](PRIVACY.md), [üçüncü taraf bildirimleri](Native/THIRD_PARTY_NOTICES.md). Samsung, Apple, Google veya OpenDisplay geliştiricilerinin resmi ürünü değildir.

## English

TabBridge is an independent GPL-3.0 derivative of OpenDisplay with a focused native Mac setup UI, Android ADB-based USB management and a small WidgetKit launcher. Both widget links and physical USB/Wi-Fi video were tested locally; S Pen click/drag was confirmed. Pressure/tilt in drawing apps, long-duration power and broader compatibility remain unverified. Development Wi-Fi has no authenticated pairing or transport encryption: use a trusted private network only. See the linked setup, validation, privacy and legal documents.
