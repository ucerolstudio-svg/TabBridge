# Privacy / Gizlilik

TabBridge requires no account or cloud relay. This fork adds no analytics or automatic diagnostic uploads. Video travels from the Mac to the selected tablet; touch and pen events travel back. Discovery uses local Bonjour; USB uses ADB forwarding. Development Wi-Fi is not authenticated or encrypted: do not use it on untrusted networks.

The Mac stores selected device identifiers and cached widget status in its own preferences. The sandboxed widget reads that preference domain through a declared read-only exception. It does not capture screens, run ADB or continuously poll devices. macOS controls refresh timing.

Local diagnostic logs are size limited. Mac logs are under `~/Library/Logs/TabBridge/`; tablet logs are in app-private storage. Logs can include device names, identifiers, endpoints and performance statistics. Review/redact before sharing. No raw personal device logs are included in source or release archives.

Screen Recording permits virtual-display transmission. Accessibility permits tablet input to Mac apps. Android requests network, Wi-Fi/multicast and wake-lock capabilities. The tablet keeps its display awake while actively connected; a low-latency Wi-Fi lock is used only for active Wi-Fi streaming. Long-duration energy usage has not been measured.

Google’s ADB/SDK, Gradle and third-party dependencies retain their own upstream licenses and behavior.

Stop transmission by disconnecting or quitting TabBridge. Revoke Mac permissions in System Settings, disable USB debugging/revoke authorized computers on Android, uninstall the tablet app and remove the Mac app/widget as desired. Removing an app alone may leave preferences/logs until deleted.

---

Hesap, bulut aktarımı veya eklenmiş TabBridge analitiği yoktur. Görüntü seçilen tablete, kalem/dokunma olayları Mac’e gönderilir. Wi-Fi geliştirme sürümünde kimlik doğrulama ve şifreleme yoktur; yalnızca güvendiğin özel ağını kullan. Yerel günlükleri paylaşmadan önce kontrol et. Aktarımı bağlantıyı keserek veya uygulamadan çıkarak durdurabilir, izinleri sistem ayarlarından geri alabilirsin.
