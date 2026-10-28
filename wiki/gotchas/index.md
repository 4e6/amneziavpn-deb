# Gotcha

* [Docker platform quirks on Apple Silicon](docker-platform-quirks-on-apple-silicon.md) - With OrbStack on an arm64 Mac, run --platform can fail to find a local amd64 image, and a registry tag can silently resolve to arm64.
* [The client's --import is not idempotent](import-is-not-idempotent.md) - Running the client with --import twice for the same config adds a duplicate server instead of recognising it.
* [The kill switch outlives the service](kill-switch-outlives-the-service.md) - Stopping or restarting the Amnezia service while connected leaves firewall rules that block all non-VPN traffic until reboot.
