#!/usr/bin/env bash
set -e

# Warna output terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

echo -e "\n${YELLOW}[*] Mendeteksi Package Manager & Menginstal Dependensi...${NC}"

if command -v dnf >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis Fedora / RHEL terdeteksi.${NC}"
    dnf install -y tailscale mosh
    systemctl enable --now tailscaled

elif command -v apt-get >/dev/null 2>&1; then
    echo -e "${GREEN}[+] Sistem berbasis Debian / Ubuntu terdeteksi.${NC}"
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
echo "----------------------------------------------------"

# Fungsi membaca input interaktif meski dieksekusi lewat pipe curl | bash
read_input() {
    local prompt_msg="$1"
    local result_var=""
    if [ -e /dev/tty ]; then
        read -r -p "$prompt_msg" result_var < /dev/tty
    else
        read -r -p "$prompt_msg" result_var
    fi
    echo "$result_var"
}

# Jika Auth Key tidak dioper lewat argumen CLI, tampilkan menu pilihan
if [ -z "$AUTH_KEY" ]; then
    echo -e "${CYAN}Pilih metode login Tailscale:${NC}"
    echo -e "  ${GREEN}1)${NC} Browser (Default) - Tampilkan link login interaktif"
    echo -e "  ${GREEN}2)${NC} Auth Key          - Input token auth key tanpa buka browser"
    echo ""
    
    CHOICE=$(read_input "$(echo -e "${YELLOW}Pilihan Anda [1/2] (Default: 1): ${NC}")")
    CHOICE="${CHOICE:-1}"

    if [ "$CHOICE" = "2" ]; then
        echo -e "\n${CYAN}[i] Dapatkan Tailscale Auth Key di:${NC}"
        echo -e "    ${BLUE}https://login.tailscale.com/admin/settings/keys${NC}\n"
        
        AUTH_KEY=$(read_input "$(echo -e "${YELLOW}Masukkan Auth Key Anda: ${NC}")")
        
        while [ -z "$AUTH_KEY" ]; do
            echo -e "${RED}[!] Auth Key tidak boleh kosong.${NC}"
            AUTH_KEY=$(read_input "$(echo -e "${YELLOW}Masukkan Auth Key Anda (atau tekan Ctrl+C untuk batal): ${NC}")")
        done
    fi
fi

echo "----------------------------------------------------"

# Eksekusi tailscale up
if [ -n "$AUTH_KEY" ]; then
    echo -e "${YELLOW}[*] Menghubungkan ke Tailnet menggunakan Auth Key...${NC}"
    tailscale up --authkey="$AUTH_KEY" --accept-routes
    echo -e "${GREEN}[✓] Berhasil terhubung via Auth Key!${NC}"
else
    echo -e "${YELLOW}[*] Menghubungkan via Browser. Buka link di bawah ini:${NC}\n"
    tailscale up --accept-routes
fi

echo "----------------------------------------------------"
IP_TAILSCALE=$(tailscale ip -4 2>/dev/null || echo "Tidak terdeteksi")
echo -e "${GREEN}[✓] Setup Selesai! Perangkat aktif di Tailnet.${NC}"
echo -e "    IP Tailscale Client : ${BLUE}${IP_TAILSCALE}${NC}"
echo -e "    Status Koneksi      : ${GREEN}Online${NC}"
echo "----------------------------------------------------"
echo -e "Cek koneksi ke server:"
echo -e "    ${YELLOW}tailscale ping <IP_OR_HOSTNAME_SERVER>${NC}"
echo -e "    ${YELLOW}mosh user@<IP_OR_HOSTNAME_SERVER>${NC}\n"
