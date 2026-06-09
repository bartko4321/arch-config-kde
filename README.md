# 🚀 Comprehensive Arch Linux & KDE Plasma Configuration

This project contains an automated configuration script (`install.sh`) that transforms a freshly installed Arch Linux system into a complete, optimized, and beautiful working environment based on the **KDE Plasma** desktop.

The script not only installs essential software, but also handles performance optimization (including gaming), hardware configuration (GPU), and automatic deployment of private configuration files (*dotfiles*).

---

## ✨ Main Features

### 1. ⚙️ System Optimization & Pacman
*   **Pacman speedup:** Enables parallel downloads (10 connections), colors, and the iconic `ILoveCandy` mode.
*   **Disk space savings (NoExtract):** Blocks extraction of unnecessary language locales (only PL and EN are kept), man pages, and redundant documentation, significantly speeding up package installation.
*   **Systemd & Logs:** Reduces service shutdown timeout (*DefaultTimeoutStopSec=3s*) and clears old system logs (older than 2 days).

### 2. 🌐 Networking & Security
*   **Privacy:** Automatically switches DNS for the active connection to fast and secure **Cloudflare** servers (IPv4 & IPv6).
*   **Firewall:** Configures `UFW` with rules allowing traffic for virtual machines.

### 3. 📦 Smart Package Installation (Pacman + AUR)
*   **GPU detection:** Automatically identifies your graphics card (**Nvidia / AMD / Intel**) and selects dedicated 32-bit graphics libraries (useful for games/Steam).
*   **Rich application set:** Developer tools, multimedia codecs, office suite (LibreOffice PL), messaging apps (Discord, Telegram), virtualization (QEMU/KVM), and gaming tools (WINE Staging, Gamemode, Mangohud).
*   **Flathub & AUR:** Automatic installation of the `yay` AUR helper, Flathub repository setup, and downloading key AUR packages (e.g. Google Chrome, Brave, Ventoy).

### 4. 🎛️ Visual Polish & Bootloader
*   **Plymouth (Early KMS):** Enables an animated boot splash (*bgrt*) integrated with kernel modules for a smooth transition from power-on to desktop.
*   **Bootloader hiding:** Reduces the GRUB/systemd-boot menu display time to 0 seconds for maximum boot speed.
*   **KDE personalization:** Automatic deployment of custom splash screens, user avatars, lock screen wallpapers, and system wallpapers in multiple resolutions.

### 5. 🐚 Modern Terminal
*   Installs and sets **ZSH** as the default user shell.
*   Installs the **Oh My Zsh** framework and the beautiful, responsive **Powerlevel10k** theme.

### 6. 📁 Automatic Dotfiles Deployment
*   Copies personalized settings from the `.config`, `.local`, and `.icons` directories.
*   **Path safety:** The script automatically detects the current username and replaces old references (e.g. `/home/bartek` paths) in configuration files with your new username, preventing broken profiles.

---

## 📁 Repository Structure

To ensure the script works correctly, maintain the following file structure in your GitHub repository:

```text
📦 your-repository
├── 📜 install.sh            # Main configuration script
├── 📜 .update.sh            # Optional update script
├── 📄 piwo.png              # User avatar
├── 📄 start.png             # Login screen wallpaper
├── 📄 plasmalogin.conf      # Login screen configuration
├── 📄 1920x1080.png         # Full HD wallpaper
├── 📄 2560x1440.png         # 2K wallpaper
├── 📄 5120x2880.png         # 5K / 4K wallpaper
├── 📂 .config/              # Your dotfiles from ~/.config
├── 📂 .local/               # Your dotfiles from ~/.local
├── 📂 .icons/               # Your icons and cursor from ~/.icons
├── 📂 splash/               # Custom KDE splash screen
└── 📂 bleachbit/            # Pre-configured BleachBit settings
```

---

## 🚀 How to Run the Script (After System Installation)

### ⚠️ Important Requirements Before Running:
1. The script **CANNOT** be run directly from the `root` account.
2. You must run it as a freshly created **regular user** with `sudo` privileges (member of the `wheel` group).

### Step-by-Step Instructions:

1. Clone this repository (replace the link with your own!)
   ```bash
   git clone https://github.com/bartko4321/arch-config-kde.git
   ```
2. Enter the downloaded folder
   ```bash
   cd arch-config-kde
   ```
3. Make the script executable
   ```bash
   chmod +x install.sh
   ```
4. Run the script and follow the on-screen instructions
   ```bash
   ./install.sh
   ```

5. Running in chroot
   ```bash
   sudo -u username /home/username/kde-config-kde/install.sh
   ```

Once finished, the script will automatically clean up temporary privileges, safely save the KDE Plasma session state to disk, and **reboot the computer**. After the restart, you'll be greeted by a fully personalized, ready-to-use system!

Bank account for support: 06291000060000000005038936

If you find this project useful, leave a star! ⭐

---
🛡️ *Use this script at your own risk. Before running it, it's worth reviewing its contents and adjusting the package list to your own preferences.*
