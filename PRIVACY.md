# Privacy / Gizlilik

TabBridge requires no account or cloud relay. This fork adds no analytics or automatic diagnostic uploads. Video travels from the Mac to the selected tablet; touch and pen events travel back. Discovery uses local Bonjour; USB uses ADB forwarding. Version 0.2.0 uses TLS 1.2/1.3 for the shipped Native Mac/Android pair. First pairing obtains the tablet certificate pin and a per-Mac random credential over explicitly authorized physical USB, never from Bonjour. All media, input and cursor traffic uses the protected stream. ADB USB also forwards to the same authenticated TLS 9443 listener; no legacy plaintext TCP 9000 or UDP listener is opened. Older releases remain unencrypted.

Wi-Fi pairing credentials are stored in the Mac Keychain, separately from preferences. Android identity keys stay in Android Keystore and peer tokens are encrypted at rest with a Keystore key; Android backup is disabled. The pairing provider is restricted to the authorized ADB shell or the app UID, in addition to a privileged manifest permission. No network pairing endpoint exports credentials. Tablet settings can forget all paired Macs and end the session. Removing the Mac app does not automatically delete Keychain items; use its forget option first if desired.

The Mac stores selected device identifiers and cached widget status in its own preferences. The sandboxed widget reads that preference domain through a declared read-only exception. It does not capture screens, run ADB or continuously poll devices. macOS controls refresh timing.

Local diagnostic logs are size limited. Mac logs are under `~/Library/Logs/TabBridge/`; tablet logs are in app-private storage. Logs can include device names, identifiers, endpoints and performance statistics. Review/redact before sharing. No raw personal device logs are included in source or release archives.

Screen Recording permits virtual-display transmission. Accessibility permits tablet input to Mac apps. Android requests network, Wi-Fi/multicast and wake-lock capabilities. The tablet keeps its display awake while actively connected; a low-latency Wi-Fi lock is used only for active Wi-Fi streaming. Long-duration energy usage has not been measured.

Google’s ADB/SDK, Gradle and third-party dependencies retain their own upstream licenses and behavior.

Stop transmission by disconnecting or quitting TabBridge. Revoke Mac permissions in System Settings, disable USB debugging/revoke authorized computers on Android, uninstall the tablet app and remove the Mac app/widget as desired. Removing an app alone may leave preferences/logs until deleted.

---

Hesap, bulut aktarımı veya eklenmiş TabBridge analitiği yoktur. Görüntü seçilen tablete, kalem/dokunma olayları Mac’e gönderilir. 0.2.0’da Native Mac/Android çifti USB üzerinden eşleşir; Wi-Fi verileri tablet sertifikası doğrulanarak TLS ile şifrelenir. Anahtarlar Mac Anahtar Zinciri ve Android Keystore ile korunur. Eski sürümler bu korumayı içermez. Tablet ayarlarından tüm eşleşmeleri iptal edebilirsin. Yerel günlükleri paylaşmadan önce kontrol et. Aktarımı bağlantıyı keserek veya uygulamadan çıkarak durdurabilir, izinleri sistem ayarlarından geri alabilirsin.
