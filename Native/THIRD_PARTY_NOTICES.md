# TabBridge attribution

TabBridge is a modified derivative of [OpenDisplay](https://github.com/peetzweg/opendisplay),
by Philip Poloczek and contributors, under GNU GPL version 3. Upstream base:
`18fc20cd4bafc160bdd6ac259142ebc11abf3f5b`.

The Mac capture/virtual-display/encoder/input pipeline and Android receiver are
retained from that work. The `Native/` Mac interface, USB Android discovery and
forwarding, setup guide and widget are TabBridge additions. Modified Android
branding and service discovery identify this development fork separately.
Original upstream source and license notices remain in the repository.

The optional USB package includes Google's official Android Debug Bridge and
its runtime library from Android SDK Platform Tools. Their third-party license
notices are bundled verbatim at `Tools/NOTICE.txt`. ADB source is available in
[Android Open Source Project](https://android.googlesource.com/platform/packages/modules/adb/).
The original development tool binaries are not claimed as TabBridge code.

AndroidX and Material dependencies retain their upstream licenses. This is an
independent development build, without a warranty of device/app compatibility,
and is not affiliated with Samsung, Apple, Google or OpenDisplay's maintainer.
