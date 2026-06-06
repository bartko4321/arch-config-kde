# 🚀 Kompleksowa Konfiguracja Arch Linux & KDE Plasma

Ten projekt zawiera zautomatyzowany skrypt konfiguracyjny (`install.sh`), który przekształca świeżo zainstalowany system Arch Linux w kompletne, zoptymalizowane i piękne środowisko pracy oparte na środowisku graficznym **KDE Plasma**.

Skrypt nie tylko instaluje niezbędne oprogramowanie, ale dba również o optymalizację pod kątem wydajności (w tym gaming), konfigurację sprzętową (GPU) oraz automatyczne wdrożenie prywatnych plików konfiguracyjnych (*dotfiles*).

---

## ✨ Główne Funkcje Skryptu

### 1. ⚙️ Optymalizacja Systemowa & Pacman
*   **Przyśpieszenie Pacmana:** Włączenie równoległego pobierania (10 połączeń), kolorów oraz kultowego trybu `ILoveCandy`.
*   **Oszczędność miejsca (NoExtract):** Blokowanie wypakowywania zbędnych lokalizacji językowych (zostają tylko PL i EN), stron podręcznika (*man pages*) oraz zbędnej dokumentacji, co znacząco przyśpiesza instalację pakietów.
*   **Systemd & Logi:** Skrócenie czasu oczekiwania na zamknięcie usług (*DefaultTimeoutStopSec=3s*) oraz czyszczenie starych logów systemowych (powyżej 2 dni).

### 2. 🌐 Sieć & Bezpieczeństwo
*   **Prywatność:** Automatyczne przestawienie DNS dla aktywnego połączenia na bezpieczne i szybkie serwery **Cloudflare** (IPv4 & IPv6).
*   **Zapora Sieciowa:** Konfiguracja `UFW` z regułami zezwalającymi na ruch dla maszyn wirtualnych.

### 3. 📦 Inteligentna Instalacja Pakietów (Pacman + AUR)
*   **Wykrywanie GPU:** Automatyczne rozpoznanie karty graficznej (**Nvidia / AMD / Intel**) i dobór dedykowanych 32-bitowych bibliotek graficznych (przydatne do gier/Steam).
*   **Bogaty zestaw aplikacji:** Narzędzia deweloperskie, kodeki multimedialne, pakiety biurowe (LibreOffice PL), komunikatory (Discord, Telegram), wirtualizacja (QEMU/KVM) oraz narzędzia do grania (WINE Staging, Gamemode, Mangohud).
*   **Flathub & AUR:** Automatyczna instalacja pomocnika `yay`, konfiguracja repozytorium Flathub oraz pobranie kluczowych pakietów z AUR (np. Google Chrome, Brave, Ventoy).

### 4. 🎛️ Wizualne Wykończenie & Bootloader
*   **Plymouth (Early KMS):** Włączenie animowanego ekranu ładowania systemu (*bgrt*) zintegrowanego z modułami jądra dla płynnego przejścia od włączenia komputera do pulpitu.
*   **Ukrycie Bootloadera:** Skrócenie czasu wyświetlania menu GRUB/systemd-boot do 0 sekund w celu maksymalnego przyśpieszenia rozruchu.
*   **Personalizacja KDE:** Automatyczne wdrożenie niestandardowych ekranów powitalnych (*Splash screen*), awatarów użytkownika, tapet ekranu blokowania oraz systemowych (w różnych rozdzielczościach).

### 5. 🐚 Nowoczesna Konsola
*   Instalacja i ustawienie **ZSH** jako domyślnej powłoki użytkownika.
*   Instalacja frameworka **Oh My Zsh** oraz pięknego, responsywnego motywu **Powerlevel10k**.

### 6. 📁 Automatyczne Wdrożenie Dotfiles
*   Kopiowanie spersonalizowanych ustawień z katalogów `.config`, `.local` oraz `.icons`.
*   **Bezpieczeństwo ścieżek:** Skrypt automatycznie wykrywa nazwę aktualnego użytkownika i podmienia stare powiązania (np. ścieżki `/home/bartek`) w plikach konfiguracyjnych na Twoją nową nazwę użytkownika, zapobiegając uszkodzeniu profili.

---

## 📁 Struktura Repozytorium

Aby skrypt działał prawidłowo, zachowaj następującą strukturę plików w swoim repozytorium na GitHubie:

```text
📦 twoje-repozytorium
├── 📜 install.sh            # Główny skrypt konfiguracyjny
├── 📜 .update.sh            # Opcjonalny skrypt aktualizacyjny
├── 📄 piwo.png              # Awatar użytkownika
├── 📄 start.png             # Tapeta startowa
├── 📄 plasmalogin.conf      # Konfiguracja ekranu logowania
├── 📄 1920x1080.png         # Tapeta w rozdzielczości Full HD
├── 📄 2560x1440.png         # Tapeta w rozdzielczości 2K
├── 📄 5120x2880.png         # Tapeta w rozdzielczości 5K / 4K
├── 📂 .config/              # Twoje dotfiles z ~/.config
├── 📂 .local/               # Twoje dotfiles z ~/.local
├── 📂 .icons/               # Twoje ikony i kursor z ~/.icons
├── 📂 splash/               # Niestandardowy ekran powitalny KDE
└── 📂 bleachbit/            # Gotowa konfiguracja programu BleachBit
```

---

## 🚀 Jak Uruchomić Skrypt (Po Instalacji Systemu)

### ⚠️ Ważne Wymagania Przed Uruchomieniem:
1. Skrypt **NIE MOŻE** być uruchamiany bezpośrednio z konta `root`.
2. Musisz uruchomić go na świeżo utworzonym **zwykłym użytkowniku**, który posiada uprawnienia do `sudo` (należy do grupy `wheel`).

### Instrukcja Krok po Kroku:

1. Po pierwszym uruchomieniu nowego systemu Arch Linux, zaloguj się do konsoli (TTY) na swoje standardowe konto użytkownika.
2. Zaktualizuj bazy danych pacmana i zainstaluj narzędzie `git`:
   ```bash
   sudo pacman -Sy git --noconfirm
   ```
3. Sklonuj to repozytorium (podmień link na swój własny!):
   ```bash
   git clone https://github.com/bartko4321/arch-config-kde.git
   ```
4. Wejdź do pobranego folderu:
   ```bash
   cd arch-config-kde
   ```
5. Nadaj skryptowi uprawnienia do wykonywania:
   ```bash
   chmod +x install.sh
   ```
6. Uruchom skrypt i postępuj zgodnie z komunikatami na ekranie:
   ```bash
   ./install.sh
   ```
   uruchamienie w chroot
sudo -u /home/nazwa-użytkownika/kde-config-kde/install.sh

Po zakończeniu pracy skrypt automatycznie wyczyści tymczasowe uprawnienia, zapisze bezpiecznie stan sesji KDE Plasma na dysku i **zrestartuje komputer**. Po restarcie przywita Cię gotowy, w pełni spersonalizowany system!

---
🛡️ *Używasz skryptu na własną odpowiedzialność. Przed uruchomieniem warto przeanalizować jego zawartość i dostosować listę instalowanych pakietów pod własne preferencje.*
