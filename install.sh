#!/usr/bin/env bash
set -e

# Warna output terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}       serversConnect - Client Auto Installer       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Validasi hak akses root / sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Harap jalankan script ini dengan sudo:${NC}"
  echo "    curl -fsSL https://raw.githubusercontent.com/prastya-dev/serversConnect/main/install.sh | sudo bash"
  exit 1
fi

AUTH_KEY="${1:-$AUTH_KEY}"

echo -e "\n${YELLOW}[*] Mendeteksi Package Manager & Sistem Operasi...${NC}"

if command -v dnf >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis Fedora / RHEL terdeteksi.${NC}"
    dnf install -y tailscale mosh
    systemctl enable --now tailscaled

elif command -v apt-get >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis Debian / Ubuntu terdeteksi.${NC}"
    # Gunakan installer resmi Tailscale untuk menambahkan repo apt terbaru
    curl -fsSL https://tailscale.com/install.sh | sh
    apt-get update -y
    apt-get install -y mosh
    systemctl enable --now tailscaled

elif command -v pacman >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis Arch Linux terdeteksi.${NC}"
    pacman -Sy --noconfirm tailscale mosh
    systemctl enable --now tailscaled

elif command -v zypper >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis openSUSE terdeteksi.${NC}"
    zypper install -y tailscale mosh
    systemctl enable --now tailscaled

else
    echo -e "${YELLOW}[!] Package manager tidak didukung langsung. Mencoba fallback script...${NC}"
    curl -fsSL https://tailscale.com/install.sh | sh
    systemctl enable --now tailscaled
fi

echo -e "\n${GREEN}[✓] Dependensi (Tailscale & Mosh) berhasil terpasang!${NC}"
echo -e "${YELLOW}[*] Memulai konfigurasi Tailscale...${NC}"
echo "----------------------------------------------------"

# Eksekusi tailscale up
if [ -n "$AUTH_KEY" ]; then
    echo -e "${YELLOW}[*] Menghubungkan menggunakan Auth Key yang diberikan...${NC}"
    tailscale up --authkey="$AUTH_KEY" --accept-routes
    echo -e "${GREEN}[✓] Berhasil terhubung ke Tailnet!${NC}"
else
    echo -e "${YELLOW}[*] Mode Interaktif: Silakan klik URL di bawah untuk login:${NC}\n"
    tailscale up --accept-routes
fi

echo "----------------------------------------------------"
IP_TAILSCALE=$(tailscale ip -4 2>/dev/null || echo "Tidak terdeteksi")
echo -e "${GREEN}[✓] Perangkat ini berhasil terdaftar di jaringan!${NC}"
echo -e "    IP Tailscale Client : ${BLUE}${IP_TAILSCALE}${NC}"
echo -e "    Status Koneksi      : ${GREEN}Online${NC}"
echo "----------------------------------------------------"
echo -e "Gunakan perintah berikut untuk tes koneksi ke server:"
echo -e "    ${YELLOW}tailscale ping <IP_OR_HOSTNAME_SERVER>${NC}"
echo -e "    ${YELLOW}mosh user@<IP_OR_HOSTNAME_SERVER>${NC}\n"
