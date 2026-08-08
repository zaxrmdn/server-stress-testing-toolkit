#!/bin/bash
# =========================================================================
# Script Simulasi Beban & Troubleshooting Server (Auto-Install Tools)
# -------------------------------------------------------------------------
# Author : Zakaria
# =========================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Mohon jalankan sebagai user root atau gunakan sudo."
  exit 1
fi

# Deteksi antarmuka jaringan utama
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Fungsi untuk otomatis menginstal tools yang dibutuhkan
install_tools() {
    echo "[+] Memeriksa dan menginstal tools yang diperlukan (stress-ng, iperf3, apache2-utils, wrk, slowhttptest)..."
    if command -v apt-get &> /dev/null; then
        apt-get update -y >/dev/null 2>&1
        apt-get install -y stress-ng iperf3 apache2-utils slowhttptest wrk >/dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        dnf install -y epel-release >/dev/null 2>&1
        dnf install -y stress-ng iperf3 httpd-tools slowhttptest wrk >/dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y epel-release >/dev/null 2>&1
        yum install -y stress-ng iperf3 httpd-tools slowhttptest wrk >/dev/null 2>&1
    fi
    echo "[+] Semua tools berhasil dipastikan tersedia!"
}

echo "====================================================="
echo "       SIMULASI BEBAN SERVER      "
echo "====================================================="
echo "        by Zakaria                                   "
echo "====================================================="
echo "1) CPU, RAM, & Disk (stress-ng)"
echo "2) Jaringan Internal (Bandwidth TCP & Nginx Killer / DDoS)"
echo "3) Jaringan Eksternal (Latensi & Packet Loss via tc)"
echo "4) MODE KIAMAT (Aktifkan Semua Beban!)"
echo "5) BERSIHKAN SEMUA BEBAN (Recovery)"
echo "====================================================="
read -p "Pilih (1-5): " mode

case $mode in
  1)
    install_tools
    echo "[+] Simulasi Beban CPU, RAM, dan Disk..."
    stress-ng --cpu $(nproc) --cpu-load 100 --timeout 3600s --quiet &
    stress-ng --vm 2 --vm-bytes 90% --vm-hang 3600 --timeout 3600s --quiet &
    stress-ng --iomix 2 --timeout 3600s --quiet &
    echo "Done!!!!! Cek menggunakan 'htop' atau 'iotop'."
    ;;

  2)
    install_tools
    echo "[+] Memulai serangan jaringan & melumpuhkan Nginx..."
    # Jalankan iperf3 server & client
    iperf3 -s -D >/dev/null 2>&1
    sleep 1
    iperf3 -c 127.0.0.1 -t 3600 -P 10 --quiet >/dev/null 2>&1 &

    # Serangan berlapis untuk melumpuhkan Web Server (Nginx/Apache)
    if systemctl is-active --quiet nginx || systemctl is-active --quiet apache2; then
        echo "    Web server terdeteksi. Melancarkan serangan brutal ke Web Server..."

        # 1. Gunakan 'wrk' jika ada (Sangat ampuh menghabiskan socket & CPU web server)
        if command -v wrk &> /dev/null; then
            echo "    Menggunakan 'wrk' (Multi-threaded HTTP Benchmarking)..."
            wrk -t12 -c2000 -d3600s http://127.0.0.1/ >/dev/null 2>&1 &
        fi

        # 2. Kombinasikan dengan Apache Benchmark (ab) skala besar
        echo "    Menggunakan 'ab' (Apache Benchmark) dengan 2500 concurrency..."
        ab -n 5000000 -c 2500 http://127.0.0.1/ >/dev/null 2>&1 &

        # 3. Slowloris sebagai tambahan pelengkap
        if command -v slowhttptest &> /dev/null; then
            slowhttptest -c 3000 -H -i 10 -r 500 -t GET -u http://127.0.0.1/ -x 24 -p 3 >/dev/null 2>&1 &
        fi
    else
        echo "    Web server tidak aktif, melewati tes HTTP."
    fi
    echo "Done!!!!! Nginx seharusnya sudah down/error 502/504. Cek via browser atau 'ss -s'."
    ;;

  3)
    echo "[+] Memanipulasi antarmuka jaringan ($INTERFACE) - Delay 100ms & Loss 5%..."
    tc qdisc add dev $INTERFACE root netem delay 100ms loss 5% 2>/dev/null
    echo "Catatan: SSH Anda ke server ini mungkin akan terasa lag/lambat!"
    ;;

  4)
    install_tools
    echo "[+] MENGAKTIFKAN MODE KIAMAT..."

    # Resource (CPU, RAM 90%, Disk)
    stress-ng --cpu $(nproc) --cpu-load 100 --timeout 3600s --quiet &
    stress-ng --vm 2 --vm-bytes 90% --vm-hang 3600 --timeout 3600s --quiet &
    stress-ng --iomix 2 --timeout 3600s --quiet &

    # Network & Web Server Downloader
    iperf3 -s -D >/dev/null 2>&1
    sleep 1
    iperf3 -c 127.0.0.1 -t 3600 -P 10 --quiet >/dev/null 2>&1 &

    if systemctl is-active --quiet nginx || systemctl is-active --quiet apache2; then
        if command -v wrk &> /dev/null; then
            wrk -t12 -c2000 -d3600s http://127.0.0.1/ >/dev/null 2>&1 &
        fi
        ab -n 5000000 -c 2500 http://127.0.0.1/ >/dev/null 2>&1 &
        if command -v slowhttptest &> /dev/null; then
            slowhttptest -c 3000 -H -i 10 -r 500 -t GET -u http://127.0.0.1/ -x 24 -p 3 >/dev/null 2>&1 &
        fi
    fi

    # Latency & Packet Loss
    tc qdisc add dev $INTERFACE root netem delay 100ms loss 5% 2>/dev/null

    echo "SELURUH SISTEM KINI LUMPUH TOTAL (Kiamat Server)!"
    ;;

  5)
    echo "[+] Membersihkan semua beban dan mengembalikan sistem..."
    killall -9 stress-ng 2>/dev/null
    killall -9 iperf3 2>/dev/null
    killall -9 ab 2>/dev/null
    killall -9 wrk 2>/dev/null
    killall -9 slowhttptest 2>/dev/null
    tc qdisc del dev $INTERFACE root 2>/dev/null
    echo "Server telah dibersihkan dan kembali normal!"
    ;;

  *)
    echo "Pilihan tidak valid!"
    ;;
esac
