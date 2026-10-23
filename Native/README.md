# TabBridge — kurulum rehberi

Galaxy Tab’ı Mac’in genişletilmiş masaüstü olarak kullanır. Bu, OpenDisplay’in
GPL-3.0 lisanslı bir türevidir; sıfırdan yazılmış bir ekran aktarım motoru değildir.
Temel proje ve katkı sahipleri: <https://github.com/peetzweg/opendisplay>.
TabBridge’in Mac arayüzü, Android USB bağlantısı, ilk kurulum akışı ve küçük
WidgetKit widget’ı `Native/` altındadır. Kaynak tabanı ve bildirimler:
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Durum ve gereksinimler

- Yerel deneme: Apple Silicon Mac, macOS 26.6; Galaxy Tab S8 Ultra SM-X906B,
  Android 16. Başka cihaz ve macOS sürümleri henüz fiziksel olarak denenmedi.
- Mac paketi arm64 için derlenmiştir. Kaynak kodun hedefi macOS 14 ve üstüdür;
  bu bir bütün sürümlerle uyumluluk garantisi değildir.
- Wi-Fi ve USB üzerinden gerçek genişletilmiş ekran, 2960 × 1848 HEVC görüntü,
  S Pen ile tıklama ve sürükleme yerel testte doğrulandı.
- Kalem basıncı, eğimi ve yakınlık iletimi kodda vardır; çizim uygulamalarında
  basınç/eğim doğruluğu henüz fiziksel olarak doğrulanmadı.
- Küçük widget’ın galeride görünmesi, eklenmesi ve iki ayrı bağlantısının
  Wi-Fi/USB aktarımını gerçekten başlatması cihaz üzerinde doğrulandı.
- Bu bir Apple Sidecar uygulaması değildir. Sidecar’ın tüm özellikleriyle
  eşdeğerlik, sıfır hata veya her Samsung modelinde çalışma sözü verilmez.

## En kısa kurulum

DMG’yi aç → TabBridge’i Applications’a sürükle → iki Mac iznini ver → tableti USB ile bağla → **Kur ve eşleştir**. Sonraki bağlantılar widget’tan Kablolu/Kablosuz ile başlar. [Kısa Türkçe/İngilizce rehber](GETTING_STARTED.txt).

Yeni güvenli Wi-Fi akışı Android 6/API 23+ gerektirir. Aşağıdaki fiziksel kullanım sonuçları önceki sürümden gelir; 0.2.0 güvenlik değişikliğinin cihaz testi ayrıca tamamlanmalıdır.

## İlk kurulum — Mac

1. `TabBridge.app` paketini Uygulamalar klasörüne taşı ve aç. Bu yerel paket
   ad hoc imzalıdır; Apple noter onaylı bir genel dağıtım paketi değildir.
2. TabBridge’de **Ekran kaydı → İzin ver** seç. Sistem Ayarları → Gizlilik ve
   Güvenlik → Ekran ve Sistem Sesi Kaydı bölümünde TabBridge’i aç.
3. **Erişilebilirlik → İzin ver** seç ve aynı adlı sistem bölümünde TabBridge’i aç.
   Bu izin S Pen/dokunma olaylarının Mac uygulamalarına iletilmesi içindir.
4. macOS isterse **Kapat ve yeniden aç** seç. Ekran aktarımı yalnızca
   bağlantı başlatıldığında çalışır.

## İlk kurulum — tablet

1. USB **veri** kablosunu Mac’e bağla. Sadece şarj eden kablo yeterli değildir.
2. Tablette Ayarlar → Tablet hakkında → Yazılım bilgileri → Yapım numarası’na
   yedi kez dokun. Gerekirse kendi ekran kilidi şifreni tablette gir.
3. Geliştirici seçenekleri ana anahtarını ve **USB hata ayıklama** seçeneğini aç.
   Anahtar griyse önce ana geliştirici anahtarını kontrol et. Samsung’un
   **Otomatik Engelleyici** ayarı da USB komutlarını engelleyebilir. Bu korumayı
   kapatmak cihazın koruma kapsamını azaltır; kablolu geliştirme bağlantısını
   yalnızca kendi güvendiğin Mac’le kullan. Kurumsal cihaz politikalarını aşma.
4. Tabletin USB hata ayıklama penceresinde kendi Mac’ine **İzin ver**.
5. Mac’te TabBridge → **Tableti bul → Kur ve eşleştir**. APK, Mac paketine dahildir.
   Birden fazla Android cihaz bağlıysa doğru tableti bir kez seç. Eşleştirme bilgisi fiziksel USB üzerinden Anahtar Zinciri’ne kaydedilir. Bu adım eski tablet uygulamasını da günceller.
6. Tablette TabBridge’i açık tut. Mac’te **Kablolu** seç.

USB modu ADB üzerinden TCP yönlendirmesi kullanır. Wi-Fi veya internete
gereksinimi yoktur. Android tarafında USB hata ayıklama bu sürümün kablolu
bağlantısı için gereklidir; doğrudan USB aksesuar protokolü değildir.

## Günlük kullanım

### Kablolu

Kabloyu tak, tabletin kilidini aç ve widget’tan ya da Mac uygulamasından
**Kablolu** seç. Mac uygulaması tabletteki alıcıyı açar ve kendi USB
yönlendirmesini kurar. Bağlantı bitince yalnızca oluşturduğu yönlendirmeyi kaldırır.

### Kablosuz

Tablette TabBridge açıkken iki cihazı aynı yerel ağa bağla. Mac’te veya
widget’ta **Kablosuz** seç. Tablet Bonjour ile bulunur; IP adresi yazmak gerekmez.
Birden fazla tablet varsa ilk kullanımda doğru olanı seç.

Kabloyu çıkarmak kendiliğinden Wi-Fi’ye geçiş başlatmaz. Önce **Kablosuz** seç.
Wi-Fi kullanımında USB hata ayıklama ve USB kablosu gerekmez.

0.2.0’da ilk USB eşleştirmesi zorunludur. Wi-Fi, USB’den alınmış tablet sertifikası
ile doğrulanır ve her Mac’e ayrı verilen rastgele anahtar üzerinden yetkilendirilir.
Görüntü, S Pen/dokunma ve imleç TLS 1.2/1.3 kullanır. Eşleşme yoksa uygulama USB
ile kurulum ister; şifresiz Wi-Fi bağlantısına geri düşmez. USB de aynı kimlik doğrulanmış TLS 9443 kanalına yönlendirilir;
düz TCP 9000 dinleyicisi yoktur.

Erişimi iptal etmek için **tablette** ayarlar → **Eşleşmiş Mac’leri unut**.
Bu işlem aktif oturumu kapatır. Yeniden bağlanmak için USB ile eşleştir.
Mac tarafındaki unut düğmesi yalnızca o Mac’in yerel kaydını kaldırır.
İki cihazı birlikte güncelle; eski 0.1.0 alıcıları yeni güvenli Wi-Fi ile çalışmaz.

### Ekranın sağda, solda veya üstte olması

TabBridge → **Ekranların konumunu ayarla** → macOS **Ekranlar → Düzenle**.
Fransızca macOS’ta **Moniteurs → Organiser…** adları kullanılır.
Tablet ekran kutusunu MacBook ekranının sağına, soluna, üstüne veya altına
sürükle ve **Bitti / Terminé** seç. Yerel sürüm tablet ekranını
`OpenDisplay — SM X906B` veya tabletin adıyla gösterir.
Fareyi ve pencereleri, tabletin kutusunun değdiği ekran kenarından geçir.

Bu ayar, tabletin yatay/dikey yönünden ayrıdır. Yatay/dikey kullanım için
tablette otomatik döndürmeyi açıp tableti çevir. Aktif ekranın boyutu
yeniden bildirilir; yeniden bağlantı gerekmez.

### S Pen ve dokunma

S Pen ile dokunma tıklar; basılı tutup hareket ettirme sürükler. İki parmakla
kaydırma desteklenir. Kalem basıncı/eğimi için Mac uygulamasının tablet kalem
olaylarını desteklemesi gerekir. Parmakları kalemle aynı anda kullanırken
kalemin hareketi önceliklidir. Uzun çizimlerde basınç/eğim ayrıca denenmelidir.

### Küçük Apple widget’ı

1. Mac uygulamasını en az bir kez aç.
2. Masaüstüne sağ tık → **Widget’ları Düzenle → TabBridge**.
3. Küçük widget’ı ekle. **Kablolu / Kablosuz** bağlantıları uygulamayı
   `tabbridge://usb` ve `tabbridge://wifi` ile başlatır.
4. Widget kendi başına ekran kaydı veya sürekli cihaz sorgusu yapmaz.
   Durum uygulamadan önbellek olarak okunur; anlık güncelleme zamanını macOS belirler.

## Enerji ve gizlilik

Aktif ekran aktarımı ekran paneli, donanım video kodlama/çözme ve bağlantı
kullanır; Mac ve tabletin tüketimini artırır. Uzun süreli pil ölçümü henüz
yapılmadı; Apple Sidecar ile aynı tüketim iddiası yoktur. Sabit görüntüde yeni
karelerin gönderilmesi azalır. USB’de Wi-Fi akış kilidi alınmaz. Kullanım
bittiğinde **Bağlantıyı kes** veya menüden **Çıkış** seç.

Hesap, bulut aktarımı veya TabBridge analitiği yoktur. Ekran ve kalem/dokunma
verileri seçilen cihaza gider. Yerel sınırlı tanı günlükleri Mac’te
`~/Library/Logs/TabBridge/`, tablette uygulamanın özel depolamasında tutulur.
Günlükler cihaz adı ve ağ bilgileri içerebilir; paylaşmadan önce kontrol et.
Google’ın Android SDK/Gradle araçlarının kendi davranışları ayrı kapsamdır.

## Sık karşılaşılan durumlar

- **USB listesi boş:** veri kablosu, tablet kilidi, geliştirici ana anahtarı,
  USB hata ayıklama ve tabletin Mac izin penceresini kontrol et.
- **Wi-Fi’de görünmüyor:** tablette TabBridge açık olmalı; misafir ağlarının
  cihaz yalıtımı Bonjour ve cihazlar arası bağlantıyı engelleyebilir.
- **Görüntü var, kalem işlemiyor:** Mac Erişilebilirlik iznini kontrol et.
- **Pencere düğmeleri yerine mor simge var:** macOS ekran paylaşım denetimi
  gösteriyor olabilir. Bu, bir pencereyi görsel olarak okuyan başka bir araçtan
  da kaynaklanabilir; yerel testte görsel yardım aracı kapatılınca normal
  düğmeler geri geldi. Simge menüsünden pencere komutlarına ulaşılabilir;
  `⌘W` kapatır, `⌘M` küçültür. TabBridge bu sistem göstergesini gizlemez.
- **Widget eski görünüyor:** uygulamayı aç, widget’ı kaldırıp yeniden ekle.
  Bağlantı işlemlerinin sonucunu uygulamanın durumundan kontrol et.

## Kaynaktan derleme

Tam kaynak ağacını kullan; `Native/` tek başına yeterli değildir. `Mac/`,
`Shared/`, `Android/` ve kökteki GPL lisansı gereklidir.

Android: JDK 17, Android SDK platform 36, build-tools 35.0.0 ve platform-tools.
`JAVA_HOME` ve `ANDROID_HOME` kendi kurulum yollarını göstermeli.

```sh
bash Native/scripts/build-android.sh
```

Bu komut yerel **geliştirme** anahtarını `build/tabbridge-debug.keystore` içinde
oluşturur. Özel imza anahtarlarını repoya veya kaynak arşivine ekleme.
APK `Android/app/build/outputs/apk/debug/app-debug.apk` yolunda oluşur.

Mac: uyumlu Swift/Apple SDK gerekir. Yerel test Swift 6.3.3 ve macOS 26.5 SDK
ile yapıldı. `TABBRIDGE_SDK` ile kendi uyumlu SDK’nı seçebilirsin.

```sh
TABBRIDGE_SDK="$(xcrun --show-sdk-path)" \
TABBRIDGE_ADB_DIR="$ANDROID_HOME/platform-tools" \
bash Native/scripts/build-macos.sh
```

Mac paketi varsayılan olarak `build/Build/Products/Debug/TabBridge.app` olur.
ADB ve Android APK’sı mevcutsa pakete eklenir. Araçlar eksikken yalnızca
uygulamanın derlenmesi USB kurulum paketinin tamam olduğu anlamına gelmez.
Widget için `NSExtensionMain` giriş noktası ve Foundation bağlantısı gereklidir;
derleme betiği bunları ekler. Yerel geliştirme kimlikleri sabittir.

Android doğrulaması:

```sh
bash Android/gradlew -p Android testDebugUnitTest lintDebug
```

Mac USB seçim testleri:

```sh
mkdir -p build/tests
swiftc -sdk "$TABBRIDGE_SDK" Native/Core/TabTypes.swift Native/Tests/main.swift \
  -o build/tests/tabbridge-usb
build/tests/tabbridge-usb
```

56 Android testi (18 kimlik doğrulama ve 3 gerçek TLS soket testi dahil), Android lint ve 8 Mac USB seçim testi geçti. Sertifika/kimlik testi: `bash Native/scripts/test-security.sh` (14 kontrol).
Görüntü aktarımı, fiziksel kalem ve widget başlatma davranışı ayrıca
cihaz üzerinde test edilmelidir.

## Lisans

GNU GPL-3.0; kökteki [LICENSE](../LICENSE) geçerlidir. Dağıtılan türev
sürümlerde karşılık gelen kaynak, lisans ve üst proje bildirimlerini koru.
Yazılım garanti verilmeden sağlanır; sorumluluk sınırları GPL’nin 15–17.
maddelerine ve uygulanabilir hukuka tabidir. Bir bildirim zorunlu tüketici
haklarını veya kanunen kaldırılamayan sorumlulukları ortadan kaldırmaz.
Samsung, Apple, Google veya OpenDisplay geliştiricilerinin resmi ürünü değildir.
