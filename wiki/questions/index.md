# Open Question

* [Does closing the app disconnect?](does-closing-the-app-disconnect.md) - The launcher connects on start, but whether closing the window or quitting from the tray drops the tunnel has not been observed.
* [Does installing through App Center or GDebi work?](does-gui-install-work.md) - The documented GUI install path (Open With → App Center, or GDebi) is based on 2024–2026 press coverage and has not been tried with this package.
* [Does the bundled server accept connections?](does-the-server-accept-connections.md) - The tunnel never completed a handshake in tests from Portugal; the server is said to be usable only from Russia, which is unverified.
* [Is --import honoured when the app is already running?](import-while-app-running.md) - If the client is already open (for example in the tray), a second launch may hand off to it and drop the --import argument.
