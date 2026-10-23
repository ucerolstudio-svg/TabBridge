# TabBridge

**Galaxy Tab’ı Mac’in ikinci ekranı yap — USB veya Wi-Fi, S Pen ve küçük Mac widget’ı.**

TabBridge, [OpenDisplay](https://github.com/peetzweg/opendisplay) temel alınarak geliştirilen bağımsız, **GPL-3.0** lisanslı bir projedir. Ekran aktarım motoru ve Android alıcısı üst projeden gelir. Basit Mac arayüzü, Android USB kurulum/bağlantı yönetimi ve küçük WidgetKit widget’ı bu projenin eklemeleridir. Üst projenin yazar ve lisans bildirimleri korunur.

> **Deneysel geliştirme sürümü.** Yerel test: Apple Silicon Mac/macOS 26.6 ve Galaxy Tab S8 Ultra SM-X906B/Android 16. Her cihazda çalışma, sıfır hata veya Apple Sidecar’ın bütün özellikleriyle eşdeğerlik iddiası yoktur.

[İndir](https://github.com/ucerolstudio-svg/TabBridge/releases) · [Adım adım kurulum](Native/README.md) · [Test sonuçları](Native/VALIDATION.md) · [Lisans](LICENSE)

## İlk kurulum

1. Releases bölümünden **macos-arm64.dmg** dosyasını indir, aç ve **TabBridge.app** simgesini yanındaki Applications klasörüne sürükle. ZIP seçeneği de kullanılabilir.
2. Uygulamayı aç. **Ekran Kaydı** ve **Erişilebilirlik** izinlerini ver. macOS isterse uygulamayı kapatıp yeniden aç. Paket yerel ad hoc imzalıdır; Apple noter onayı henüz yoktur.
3. Tableti USB **veri** kablosuyla bağla. Geliştirici seçenekleri → **USB hata ayıklama** seçeneğini aç ve tablette kendi Mac’ine izin ver.
4. Mac’te **Tableti bul → Kur ve eşleştir** seç. Paketteki Android uygulaması kurulur ve bu Mac’in Wi-Fi eşleşmesi fiziksel USB üzerinden kaydedilir. IP adresi veya şifre yazman gerekmez.
5. **Kablolu** seç. Sonraki kablosuz kullanımlarda tablette TabBridge açıkken aynı ağa bağlanıp **Kablosuz** seç. İlk eşleştirmeden sonra kabloyu çıkarabilir, Wi-Fi kullanırken USB hata ayıklamayı kapatabilirsin.
6. Küçük widget: masaüstüne sağ tık → **Widget’ları Düzenle → TabBridge**. Sonraki bağlantıları **Kablolu / Kablosuz** düğmelerinden başlat.

Samsung Otomatik Engelleyici, USB hata ayıklamayı engelleyebilir. Güvenlik etkileri, gri anahtar, Mac izin sorunları ve derleme adımları [tam rehberde](Native/README.md) açıklanır.

## Kullanım

- **Gerçek ikinci ekran:** Mac pencerelerini tablete sürükle.
- **Sağ/sol/üst konum:** TabBridge → Ekranların konumunu ayarla → Düzenle. Tablet kutusunu MacBook’un istediğin kenarına taşı. Fransızca macOS: *Moniteurs → Organiser… → Terminé*.
- **Kalem:** S Pen ile tıkla ve sürükle; iki parmakla kaydır. Basınç/eğim iletimi kodda vardır; çizim uygulamalarında doğruluğu henüz doğrulanmadı.
- **Bağlantı değişimi:** Widget’tan modu seç. Kabloyu çıkarmak kendiliğinden Wi-Fi’ye geçiş başlatmaz.
- **Bitir:** Uygulamada Bağlantıyı kes veya menü çubuğunda Çıkış.

## Doğrulananlar ve sınırlar

Yeni 0.2.0 adayında 56 Android testi (gerçek TLS soketleriyle kabul/ret testleri dahil), Android lint, 14 Mac eşleştirme/sertifika testi ve 8 USB seçim testi geçti. Önceki 0.1.0 sürümünün fiziksel USB/Wi-Fi ekran, widget ve S Pen sonuçları [burada](Native/VALIDATION.md) korunur. Yeni güvenlik akışının gerçek tablet testi yayın öncesi tamamlanmalıdır; eski test sonuçları yeni akışın cihaz doğrulaması sayılmaz.

## Güvenli Wi-Fi eşleştirmesi — 0.2.0

- İlk eşleştirme yalnızca Mac’in `usb:` olarak doğruladığı, kullanıcı tarafından yetkilendirilmiş ADB USB bağlantısından yapılır.
- Tablet kimliği Mac Anahtar Zinciri’ne kaydedilir. Wi-Fi bağlantısında bu sertifikanın SHA-256 izi doğrulanır; Bonjour adı veya ağdan gelen kimlik bilgisi güven kaynağı değildir.
- Her Mac için ayrı, rastgele 256 bit erişim anahtarı kullanılır. Tablette Android Keystore anahtarıyla korunur. Anahtarlar günlük, kaynak arşivi veya widget’a yazılmaz.
- Görüntü, dokunma/S Pen ve imleç TLS 1.2/1.3 üzerinden gider. Ayrı UDP imleç dinleyicisi açılmaz. USB yönlendirmesi de aynı doğrulanmış TLS 9443 kanalını kullanır. Düz TCP 9000 dinleyicisi açılmaz.
- Eşleşmemiş istemci görüntü başlatamaz veya aktif oturumu değiştiremez. Yeniden bağlantıda da aynı denetim uygulanır; şifresiz ağa geri düşme yoktur.
- Erişimi kaldırmak için **tablette** ayarlar → **Eşleşmiş Mac’leri unut** seç. Bağlantı kesilir ve anahtarlar silinir. Mac’teki unut düğmesi yalnızca o Mac’in yerel kaydını siler.

**Mac ve tablet uygulamasını birlikte güncelle.** Eski 0.1.0 paketleri şifrelenmez; yeni Mac eski tabletle Wi-Fi bağlantısı kurmaz. Bu koruma dağıtılan Native Mac/Android çifti içindir; kaynakta korunan özgün OpenDisplay, iOS, Linux ve Mac alıcı hedeflerinin güvenliğini değiştirdiği iddia edilmez.

Android 6/API 23+ gerekir. İlk USB kurulumundan sonra Wi-Fi kullanımı için ADB ağ modunu açma; gerekmez. Kaybolan veya güvenilmeyen bir Mac’in erişimini tablet üzerinden kaldır. Mac/tablet işletim sisteminin veya yetkilendirilmiş ADB bilgisayarının ele geçirilmesine karşı koruma iddiası yoktur.

Aktif aktarım Mac ve tabletin pil tüketimini artırır; uzun süreli pil ölçümü yapılmadı. Donanım video kodlama/çözme kullanılır. Kalıcı sistem sürücüsü kurulmaz; geçici sanal ekran ve ScreenCaptureKit kullanılır. Sanal ekranın özel macOS API’si gelecekteki sistem sürümlerinde uyumluluk riski taşır. Uyku/uyanma, uzun oturumlar ve başka modeller ayrıca denenmelidir.

## Geliştirme ve lisans

[Kaynaktan derleme ve test komutları](Native/README.md#kaynaktan-derleme). Mac için Native derleme betiğini kullan. Üst projenin özgün hedefleri ve [README’si](README-OpenDisplay.md) kaynakta korunmuştur; bunların bütün platform iddiaları TabBridge için test edilmiş değildir.

**GPL-3.0.** Yazılım garanti verilmeden sunulur. Dağıtırken karşılık gelen kaynak ve lisans bildirimlerini koru. [Hukuki bildirim](LEGAL.md), [gizlilik](PRIVACY.md), [üçüncü taraf bildirimleri](Native/THIRD_PARTY_NOTICES.md). Samsung, Apple, Google veya OpenDisplay geliştiricilerinin resmi ürünü değildir.

## English

TabBridge is an independent GPL-3.0 derivative of OpenDisplay with a focused native Mac setup UI, Android ADB-based USB management and a small WidgetKit launcher. Both widget links and physical USB/Wi-Fi video were tested locally; S Pen click/drag was confirmed. Pressure/tilt in drawing apps, long-duration power and broader compatibility remain unverified. Version 0.2.0 adds physical-USB bootstrapping, a Keychain-pinned tablet certificate and per-Mac random credentials over TLS 1.2/1.3. Video, pen/touch and cursor share that connection; there is no UDP listener or plaintext LAN fallback. Both peers must be upgraded. Android API 23+ is required. The new flow still requires hardware validation before release. See the linked setup, validation, privacy and legal documents.
