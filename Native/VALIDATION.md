# Local validation — 2026-10-23

Development build 0.1.0; arm64 Mac on macOS 26.6, Galaxy Tab S8 Ultra
SM-X906B on Android 16. No identifiers, private addresses or raw device logs
are included in this report.

| Check | Result |
| --- | --- |
| Android debug build | Passed |
| Android JVM tests | 35 passed, 0 failures, 0 errors |
| Android lintDebug | Passed; existing warnings remain |
| Mac native + WidgetKit extension build | Passed; upstream Swift 5 concurrency warnings remain |
| Mac USB target selection tests | 8 passed |
| App/extension deep strict code signature verification | Passed; ad hoc local signature |
| Physical USB extended display | Passed; loopback TCP over ADB; tablet reported USB |
| Physical Wi-Fi extended display | Passed; Bonjour discovery; tablet reported WiFi |
| Native small widget gallery/add | User confirmed |
| Widget wireless deep link to actual capture | Passed; host received wifi and tablet decoded HEVC frames |
| Widget wired deep link to actual capture | Passed; host received usb and tablet decoded HEVC frames |
| Display resolution | 2960 × 1848 HEVC, configured 60 fps |
| Display arrangement between transport changes | Saved left placement restored |
| S Pen click/drag | User confirmed |
| Pressure/tilt in drawing applications | Not yet verified on hardware |
| Long-duration power, sleep/wake, rotation stress, other models/OS versions | Not yet verified |
| Secure Wi-Fi pairing/encrypted transport | Not implemented in this development fork |
| Public release signing/notarization | Not done |

An initial App Intents widget build rendered but could not dispatch actions.
It was replaced with two explicit Link destinations, supported by current
WidgetKit, routed through the host's existing application(_:open:) handler.
Both real widget links were tested after the fix. The extension uses the
NSExtensionMain entry point. The first local signing identity change required
resetting only TabBridge's stale TCC entries and granting permissions again.
Future local builds use a stable explicit designated requirement; grant
persistence across a future rebuild has not been claimed as measured.

The user's missing traffic-light controls returned when the development
assistant's visual window inspection was stopped. The Mac app itself uses
native NSWindow title-bar controls.

These results describe this short local session, not a claim of zero bugs,
Sidecar parity, measured universal 60 fps, or support for every device.
