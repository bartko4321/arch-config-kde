#!/bin/bash
# ==========================================================
# KOMPLEKSOWY SKRYPT KONFIGURACYJNY SYSTEMU (KDE PLASMA + ARCH)
# ==========================================================

set -euo pipefail

# ============================================================
# KOLORY I LOGOWANIE
# ============================================================
INFO='\033[0;34m'
SUCCESS='\033[0;32m'
WARN='\033[0;33m'
NC='\033[0m'

log_info()    { echo -e "${INFO}==> $*${NC}"; }
log_ok()      { echo -e "${SUCCESS}==> $*${NC}"; }
log_warn()    { echo -e "${WARN}==> UWAGA: $*${NC}"; }

# Upewnij się, że skrypt NIE jest uruchamiany jako root
if [[ "$EUID" -eq 0 ]]; then
    log_warn "BŁĄD: Nie uruchamiaj skryptu jako root. Uruchom jako zwykły użytkownik z sudo." >&2
    exit 1
fi

# ============================================================
# FUNKCJE POMOCNICZE (FILTROWANIE PAKIETÓW)
# ============================================================
install_pacman_pkgs() {
    local valid_pkgs=()
    for pkg in "$@"; do
        if pacman -Si "$pkg" &>/dev/null; then
            valid_pkgs+=("$pkg")
        else
            log_warn "Pomijam pakiet (nie znaleziono w repozytorium): $pkg"
        fi
    done

    if [ ${#valid_pkgs[@]} -gt 0 ]; then
        sudo pacman -S --noconfirm --needed "${valid_pkgs[@]}"
    else
        log_warn "Brak prawidłowych pakietów do zainstalowania z podanej listy."
    fi
}

install_yay_pkgs() {
    local valid_pkgs=()
    for pkg in "$@"; do
        if yay -Si "$pkg" &>/dev/null; then
            valid_pkgs+=("$pkg")
        else
            log_warn "Pomijam pakiet AUR (nie znaleziono): $pkg"
        fi
    done

    if [ ${#valid_pkgs[@]} -gt 0 ]; then
        yay -S --noconfirm --needed "${valid_pkgs[@]}"
    else
        log_warn "Brak prawidłowych pakietów AUR do zainstalowania z podanej listy."
    fi
}

# ============================================================
# ZMIENNE I ŚRODOWISKO
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="$(whoami)"
OLD_USER_PLACEHOLDER="bartek"

# Wykrywanie układu graficznego (wymagane dla Bootloadera i Plymouth)
GPU_TYPE="unknown"
if command -v lspci &>/dev/null; then
    if lspci | grep -i 'vga\|3d\|display' | grep -qi 'nvidia'; then
        GPU_TYPE="nvidia"
    elif lspci | grep -i 'vga\|3d\|display' | grep -qi 'amd\|radeon'; then
        GPU_TYPE="amd"
    elif lspci | grep -i 'vga\|3d\|display' | grep -qi 'intel'; then
        GPU_TYPE="intel"
    fi
fi

# ============================================================
# 1. KONFIGURACJA (BEZ SUDO)
# ============================================================
log_info "Przygotowanie konfiguracji użytkownika..."

# Opcjonalny skrypt aktualizacji
if [ -f "$SCRIPT_DIR/.update.sh" ]; then
    cp -af "$SCRIPT_DIR/.update.sh" ~/.update.sh
    chmod +x ~/.update.sh
fi

# ============================================================
# SEKCJA SUDO — KONFIGURACJA SYSTEMOWA
# ============================================================
log_info "Rozpoczynanie konfiguracji systemowej (wymaga sudo)..."

# Pobranie hasła i ustawienie tymczasowego wyjątku, aby yay/pacman nie pytały o hasło
sudo -v
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-temp-installer > /dev/null

# ============================================================
# 3. USUWANIE NIECHCIANYCH PAKIETÓW
# ============================================================
PACKAGES_TO_REMOVE="htop nano plasma-browser-integration plasma-vault konqueror krdp plasma-thunderbolt gnome-software epiphany decibels rhythmbox showtime cosmic-store cosmic-player parole"

INSTALLED_PACKAGES=$(pacman -Qq $PACKAGES_TO_REMOVE 2>/dev/null || true)
if [ -n "$INSTALLED_PACKAGES" ]; then
    log_info "Usuwanie zbędnych pakietów..."
    # shellcheck disable=SC2086
    sudo pacman -Rs --noconfirm $INSTALLED_PACKAGES 2>/dev/null || true
fi


# 4. OPTYMALIZACJA PACMANA
# ============================================================
log_info "Optymalizacja /etc/pacman.conf..."

sudo sed -i 's/^#[[:space:]]*Color/Color/' /etc/pacman.conf
if ! grep -qw "ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi
sudo sed -i 's/^[[:space:]]*CheckSpace/#CheckSpace/' /etc/pacman.conf
sudo sed -i 's/^#[[:space:]]*ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i 's/^#[[:space:]]*VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

# Blokowanie wypakowywania wszystkich języków z wyjątkiem PL i EN oraz dokumentacji CUPS
log_info "Dodawanie reguł NoExtract (języki i dokumentacja CUPS)..."
if ! grep -q "NoExtract = usr/share/locale" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a NoExtract = usr/share/locale/* !usr/share/locale/pl* !usr/share/locale/en*\nNoExtract = usr/share/cups/doc/*' /etc/pacman.conf
fi

# Blokowanie wypakowywania dokumentacji i stron podręcznika
log_info "Dodawanie reguł NoExtract (dokumentacja i man pages)..."
if ! grep -q "NoExtract = usr/share/man" /etc/pacman.conf; then
    sudo sed -i '/NoExtract = usr\/share\/cups\/doc/a NoExtract = usr/share/man/*\nNoExtract = usr/share/doc/*\nNoExtract = usr/share/info/*\nNoExtract = usr/share/gtk-doc/*\nNoExtract = usr/share/help/*' /etc/pacman.conf
fi

# Przeinstalowanie pakietu cups, aby zastosować reguły i wyczyścić stare pliki
log_info "Instalacja/Przeinstalowanie CUPS..."
sudo pacman -S --noconfirm cups

# ============================================================
# 5. DNS CLOUDFLARE
# ============================================================
log_info "Ustawianie DNS Cloudflare..."
CONNECTION_NAME="$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n 1 || true)"
if [ -n "$CONNECTION_NAME" ]; then
    sudo nmcli connection modify "$CONNECTION_NAME" ipv4.dns "1.1.1.1 1.0.0.1"
    sudo nmcli connection modify "$CONNECTION_NAME" ipv4.ignore-auto-dns yes
    sudo nmcli connection modify "$CONNECTION_NAME" ipv6.dns "2606:4700:4700::1112 2606:4700:4700::1002"
    sudo nmcli connection modify "$CONNECTION_NAME" ipv6.ignore-auto-dns yes
    sudo nmcli connection up "$CONNECTION_NAME" || true
fi

# ============================================================
# 6. INSTALACJA PAKIETÓW SYSTEMOWYCH
# ============================================================
log_info "Aktualizacja bazy i instalacja pakietów systemowych..."
sudo pacman -Sy --noconfirm

SYSTEM_PKGS=(
    # System i narzędzia
    base-devel git zsh pacman-contrib btop fastfetch reflector
    gcc make cmake meson ninja just
    python-pip python-tqdm python-defusedxml python-packaging

    # Zarządzanie KDE Plasma
    plasma-firewall plasma-nm plasma-pa kscreen bluedevil kde-gtk-config
    kinfocenter kio-admin kdeplasma-addons aspell-pl kaccounts-providers dolphin konsole dolphin-plugins
    spectacle gwenview okular ark kate

    # Zarządzanie systemem i dyskami
    partitionmanager bleachbit unrar mc btrfs-progs exfat-utils ntfs-3g os-prober
    fsarchiver inxi pv rsync 7zip zenity innoextract android-tools dnsmasq vde2

    # Narzędzia wizualne i systemowe
    plymouth profile-sync-daemon ananicy-cpp dconf-editor geoclue fwupd fwupd-efi
    bluez-obex appmenu-gtk-module libayatana-appindicator flatpak

    # Multimedia i grafika
    vlc vlc-plugins-all libappimage
    krita krita-plugin-gmic gimp gmic
    audacity qmmp mixxx kdenlive
    gst-plugins-good gst-plugins-bad gst-plugins-ugly

    # Komunikatory i sieć
    discord telegram-desktop qbittorrent

    # Biuro
    libreoffice-fresh libreoffice-fresh-pl hunspell-pl

    # WINE, Gaming i Wirtualizacja
    wine-staging winetricks gamemode gamescope mangohud goverlay vkd3d
    vulkan-dzn vulkan-gfxstream vulkan-swrast
    virt-manager qemu-desktop libvirt edk2-ovmf

    # Biblioteki 32-bit (zoptymalizowane - bez duplikatów)
    lib32-mpg123 lib32-libvdpau lib32-libtheora lib32-speex
    lib32-libxrandr lib32-libxrender lib32-gamemode
    lib32-vulkan-swrast lib32-vkd3d lib32-alsa-plugins
    lib32-libpulse lib32-openal lib32-mangohud lib32-pipewire
)

# ── Dynamiczne dodawanie pakietów 32-bit dla GPU ──────────────
log_info "Dobieranie 32-bitowych bibliotek graficznych dla wykrytego układu: $GPU_TYPE"

case "$GPU_TYPE" in
    "nvidia")
        SYSTEM_PKGS+=(lib32-nvidia-utils lib32-vulkan-icd-loader)
        ;;
    "amd")
        SYSTEM_PKGS+=(lib32-vulkan-radeon lib32-mesa lib32-vulkan-mesa-layers lib32-mesa-utils lib32-vulkan-icd-loader)
        ;;
    "intel")
        SYSTEM_PKGS+=(lib32-libva-intel-driver lib32-vulkan-intel lib32-mesa lib32-vulkan-mesa-layers lib32-mesa-utils lib32-vulkan-icd-loader)
        ;;
    *)
        log_warn "GPU nierozpoznane lub brak specyficznych bibliotek 32-bit."
        ;;
esac

install_pacman_pkgs "${SYSTEM_PKGS[@]}"

log_info "Dodawanie repozytorium Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ============================================================
# 7. BOOTLOADER I KERNEL CMDLINE
# ============================================================
log_info "Konfiguracja bootloadera i /etc/kernel/cmdline..."
CMDLINE="quiet splash plymouth.ignore-serial-consoles"
[[ $GPU_TYPE == *"nvidia"* ]] && CMDLINE="$CMDLINE nvidia_drm.modeset=1"

# /etc/kernel/cmdline
if [ -f /etc/kernel/cmdline ] && ! grep -q "quiet splash" /etc/kernel/cmdline; then
    sudo sed -i "s/$/ $CMDLINE/" /etc/kernel/cmdline
    sudo sed -i 's/  */ /g'     /etc/kernel/cmdline
fi

# systemd-boot
for loader_root in "/boot" "/efi"; do
    [ ! -d "$loader_root/loader/entries" ] && continue
    [ -f "$loader_root/loader/loader.conf" ] && \
        sudo sed -i 's/^timeout .*/timeout 0/' "$loader_root/loader/loader.conf"
    for entry in "$loader_root/loader/entries/"*.conf; do
        [ -f "$entry" ] && ! grep -q "quiet splash" "$entry" || continue
        sudo sed -i "/^options/ s/$/ $CMDLINE/" "$entry"
        sudo sed -i 's/  */ /g' "$entry"
    done
done

# GRUB
if [ -f /etc/default/grub ]; then
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    if ! grep -q "plymouth.ignore-serial-consoles" /etc/default/grub; then
        sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$CMDLINE\"|" /etc/default/grub
    fi
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || \
    sudo grub-mkconfig -o /boot/GRUB/grub.cfg 2>/dev/null || true
fi

# ============================================================
# 8. PLYMOUTH + EARLY KMS
# ============================================================
log_info "Konfiguracja Plymouth i modułów initramfs..."
sudo plymouth-set-default-theme -R bgrt 2>/dev/null || true

if [[ $GPU_TYPE == *"nvidia"* ]]; then
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
elif [[ $GPU_TYPE == *"amd"* ]]; then
    sudo sed -i 's/^MODULES=(/MODULES=(amdgpu /'  /etc/mkinitcpio.conf
elif [[ $GPU_TYPE == *"intel"* ]]; then
    sudo sed -i 's/^MODULES=(/MODULES=(i915 /'    /etc/mkinitcpio.conf
fi

sudo sed -i 's/^#Theme=.*/Theme=bgrt/'       /etc/plymouth/plymouthd.conf 2>/dev/null || true
sudo sed -i 's/^#ShowDelay=.*/ShowDelay=0/'  /etc/plymouth/plymouthd.conf 2>/dev/null || true

for preset in /etc/mkinitcpio.d/*.preset; do
    [ -f "$preset" ] && sudo sed -i 's/--splash [^ "]*//g' "$preset"
done

if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    sudo sed -i 's/udev/udev plymouth/' /etc/mkinitcpio.conf
fi

sudo mkinitcpio -P

# ============================================================
# 9. USŁUGI SYSTEMOWE, FIREWALL, CZYSZCZENIE LOGÓW
# ============================================================
log_info "Usługi, Firewall i optymalizacja logów..."

# UFW — zezwolenie na forward dla maszyn wirtualnych
if [ -f /etc/default/ufw ]; then
    sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi

if command -v ufw &>/dev/null; then
    sudo systemctl enable --now ufw || true
    sudo ufw allow in  on virbr0 || true
    sudo ufw allow out on virbr0 || true
fi

# Włączanie usług
sudo systemctl enable --now geoclue.service || true
sudo systemctl enable --now ananicy-cpp || true
sudo systemctl enable --now fstrim.timer || true
sudo systemctl enable --now bluetooth || true
echo "options btusb enable_autosuspend=0" | sudo tee /etc/modprobe.d/btusb.conf
sudo systemctl enable --now libvirtd || true
sudo virsh net-autostart default || true

# Skrócenie domyślnego timeoutu zatrzymywania usług do 3s
sudo sed -i 's/^#\?[[:space:]]*DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=3s/' /etc/systemd/system.conf

# Wyłączenie zbędnej usługi opóźniającej boot
sudo systemctl disable NetworkManager-wait-online.service || true

# Czyszczenie dziennika (ostatnie 2 dni)
sudo journalctl --vacuum-time=2d || true

# ============================================================
# 10. PERSONALIZACJA (SPLASH, AVATAR, BLEACHBIT, TAPETY)
# ============================================================
log_info "Personalizacja systemu (ikony, awatary, tapety)..."

SPLASH_DEST="/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/splash"
if [ -d "$SCRIPT_DIR/splash" ]; then
    sudo rm -rf "$SPLASH_DEST"
    sudo cp -af "$SCRIPT_DIR/splash" /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/
fi

if [ -f "$SCRIPT_DIR/piwo.png" ]; then
    sudo mkdir -p /usr/share/plasma/avatars/ /var/lib/AccountsService/icons/
    sudo cp -af "$SCRIPT_DIR/piwo.png" /usr/share/plasma/avatars/piwo.png
    sudo cp -af "$SCRIPT_DIR/piwo.png" /var/lib/AccountsService/icons/"$CURRENT_USER"
fi

[ -f "$SCRIPT_DIR/start.png" ]        && sudo cp -af "$SCRIPT_DIR/start.png"        /usr/share/wallpapers/start.png
[ -f "$SCRIPT_DIR/plasmalogin.conf" ] && sudo cp -af "$SCRIPT_DIR/plasmalogin.conf" /etc/plasmalogin.conf

log_info "Podmiana tapet w motywie Next..."
TARGET_DIR="/usr/share/wallpapers/Next/contents/images"

for res in 1920x1080 2560x1440 5120x2880; do
    if [ -f "$SCRIPT_DIR/$res.png" ]; then
        sudo mkdir -p "$TARGET_DIR/contents/images"
        sudo cp -f "$SCRIPT_DIR/$res.png" "$TARGET_DIR/$res.png"
        sudo cp -f "$SCRIPT_DIR/$res.png" "$TARGET_DIR/contents/images/$res.png"
        sudo chmod 644 "$TARGET_DIR/$res.png" "$TARGET_DIR/contents/images/$res.png"
    else
        log_warn "Brak pliku $res.png w katalogu ze skryptem - pomijam."
    fi
done

sudo mkdir -p /usr/share/wallpapers/Next/contents/images_dark/
if [ -f "$SCRIPT_DIR/5120x2880.png" ]; then
    sudo cp -f "$SCRIPT_DIR/5120x2880.png" /usr/share/wallpapers/Next/contents/images_dark/5120x2880.png
    sudo chmod 644 /usr/share/wallpapers/Next/contents/images_dark/5120x2880.png
fi

# Konfiguracja BleachBit dla roota
if [ -d "$SCRIPT_DIR/bleachbit" ]; then
    sudo mkdir -p /root/.config/bleachbit
    sudo cp -af "$SCRIPT_DIR/bleachbit/." /root/.config/bleachbit/
    log_ok "Skopiowano konfigurację BleachBit."
else
    log_warn "Folder $SCRIPT_DIR/bleachbit nie istnieje — pomijam."
fi

# ============================================================
# 11. GRUPY (WIRTUALIZACJA)
# ============================================================
sudo usermod -aG libvirt,kvm "$CURRENT_USER"

# ============================================================
# 12. ZSH + OH-MY-ZSH + POWERLEVEL10K
# ============================================================
log_info "Konfiguracja ZSH i Powerlevel10k..."
if command -v zsh &>/dev/null; then
    sudo chsh -s /usr/bin/zsh "$CURRENT_USER"

    [ ! -d "$HOME/.oh-my-zsh" ] && \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    [ ! -d "$P10K_DIR" ] && \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || true

    if [ -f ~/.zshrc ]; then
        sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
        if ! grep -q "LC_ALL=pl_PL.UTF-8" ~/.zshrc; then
            {
                echo ""
                echo "export LC_ALL=pl_PL.UTF-8"
                echo "export LC_MESSAGES=pl_PL.UTF-8"
                echo "fastfetch"
            } >> ~/.zshrc
        fi
    fi
fi

# ============================================================
# 13. YAY (AUR HELPER) I PAKIETY AUR
# ============================================================
log_info "Instalacja yay i pakietów AUR..."

if ! command -v yay &>/dev/null; then
    rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

yay --save --cleanafter --cleanmenu=false --diffmenu=false --editmenu=false

AUR_PKGS=(ventoy-bin lsfg-vk-bin google-chrome brave-bin faugus-launcher shelly-bin dmemcg-booster needrestart makeself)
install_yay_pkgs "${AUR_PKGS[@]}"

# ============================================================
# 14. FINALIZACJA I RESTART
# ============================================================
log_info "Zatrzymywanie środowiska KDE, aby nie nadpisało naszych zmian..."
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
sleep 2

log_info "Kopiowanie plików konfiguracyjnych na uśpionym środowisku..."
if [[ -d "$SCRIPT_DIR/.config" ]]; then cp -af "$SCRIPT_DIR/.config/." ~/.config/; fi
if [[ -d "$SCRIPT_DIR/.local" ]]; then cp -af "$SCRIPT_DIR/.local/." ~/.local/; fi
if [[ -d "$SCRIPT_DIR/.icons" ]]; then cp -af "$SCRIPT_DIR/.icons/." ~/.icons/; fi

# Podmiana ścieżki (zabezpieczenie)
if [[ "$OLD_USER_PLACEHOLDER" != "$CURRENT_USER" ]]; then
    find ~/.config -type f -exec sed -i "s|/home/$OLD_USER_PLACEHOLDER|/home/$CURRENT_USER|g" {} + 2>/dev/null || true
fi

log_info "Czyszczenie pamięci podręcznej (Cache)..."
rm -rf ~/.cache/icon-cache.kcache ~/.cache/plasma* ~/.cache/ico*

# Odpalamy chwilowo Plasmę w tle (wczyta już Twoje skopiowane przed chwilą ustawienia .config)
plasmashell >/dev/null 2>&1 &
sleep 5

# Zabijamy proces drugi raz. Plasma zrzuci stan RAMu na dysk - zapisując Twoją konfigurację
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
sleep 2

# Odbudowa bazy systemowej
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 --noincremental &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 --noincremental &>/dev/null || true
fi

log_ok "Sprzątanie uprawnień i finalizacja..."
sudo rm -f /etc/sudoers.d/99-temp-installer

log_ok "KONFIGURACJA ZAKOŃCZONA SUKCESEM!"
sleep 3
systemctl reboot
