# Initial Configuration for Raspberry Pi OS

## Raspberry Pi Configuration

```bash
sudo raspi-config
```

1. Change the password for user "pi"
2. Disable the boot to desktop option: Boot Options -> B1 Desktop / CLI -> Select B2 Console Autologin
3. Update local settings:
	* US-UTF8
	* Timezone PDT
4. Set your Hostname: Advanced -> Hostname
5. Set the Memory Split: Advanced -> Memory Split -> GPU = 16Mb
6. Ensure SSH is enabled: Advanced -> SSH
7. Commit Changes and exit.

```bash
sudo reboot
```
