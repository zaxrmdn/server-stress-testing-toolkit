# 🛠️ Linux Performance Tuning 

Repositori ini berisi *automation script* yang dirancang khusus untuk keperluan workshop bertema **Performance Tuning Linux: Optimasi CPU, Memory, Disk, dan Network untuk Sysadmin**.

Script utama di dalam untuk mensimulasikan berbagai anomali dan beban sistem secara nyata (*real-world production issues*) pada mesin Virtual Machine peserta.

---

## 🚀 Fitur Script Load-test

Script ini sudah dilengkapi fitur **Auto-Install** (secara otomatis mendeteksi dan menginstal *tools* pendukung seperti `stress-ng`, `iperf3`, `wrk`, dll). Berikut adalah menu pilihan simulasi yang tersedia:

1. **CPU, RAM, & Disk Bottleneck (`stress-ng`)**
   * Memaksa penggunaan CPU 100% di seluruh *core*.
   * Menguras alokasi RAM hingga 90% untuk memicu *Swap* dan *OOM Killer*.
   * Melakukan *stress-test* pada operasi baca/tulis Disk I/O.
2. **Jaringan Internal & Web Server Killer (DDoS Simulation)**
   * Menguji *bandwidth* internal menggunakan `iperf3`.
   * Melumpuhkan web server lokal (Nginx/Apache) menggunakan kombinasi **`wrk`** (*multi-threaded HTTP benchmarking* berkecepatan tinggi), **Apache Benchmark (`ab`)** dengan *concurrency* ekstrem, dan **`slowhttptest`** (*Slowloris attack*).
3. **Jaringan Eksternal (Latensi & Packet Loss via `tc`)**
   * Memanipulasi *network interface* dengan menambahkan *delay* (latensi) sebesar 100ms dan *packet loss* 5% untuk mensimulasikan jaringan yang buruk.
4. **MODE KIAMAT (All-in-One Crisis)**
   * Mengeksekusi seluruh simulasi di atas secara bersamaan untuk membuat server mengalami kelumpuhan total (CPU habis, RAM kritis, I/O penuh, Web Server *down*, dan Jaringan lag).
5. **Recovery / Clean Up**
   * Membersihkan seluruh proses latar belakang (*background processes*) dan mengembalikan konfigurasi jaringan seperti semula dalam satu perintah instan.

---

## ⚙️ Persyaratan Sistem & Instalasi

* Sistem Operasi: Linux (Ubuntu / Debian / RHEL / CentOS / Rocky Linux)
* Hak Akses: `root` atau hak istimewa `sudo`

### Cara Penggunaan (Untuk Trainer):
1. Unduh atau *clone* repositori ini ke server/VM latihan:
```
git clone [https://github.com/zaxrmdn/server-stress-testing-toolkit.git]
cd server-stress-testing-toolkit
```
2. Berikan izin eksekusi pada script:

```
chmod +x stress-test.sh
```

3. Jalankan script dengan hak akses root:
```
sudo ./stress-test.sh
```

4. Pilih nomor simulasi yang diinginkan (1 s.d. 5) sesuai dengan skenario materi workshop yang sedang disampaikan.

---

### Penjelasan Detail Komponen *Script* 

Jika ada peserta atau rekan yang bertanya mengenai cara kerja *script* tersebut, berikut adalah rincian teknis dari fungsi-fungsinya:

1. **Deteksi Hak Akses (`$EUID`)**: Memastikan *script* hanya bisa dieksekusi oleh *root* atau *sudoer*, karena perintah seperti manipulasi jaringan (`tc`) dan instalasi paket memerlukan hak istimewa sistem tertinggi.
2. **Auto-Install (`install_tools`)**: Berfungsi mendeteksi manajer paket sistem operasi (`apt-get` untuk Ubuntu/Debian atau `dnf`/`yum` untuk keluarga RedHat), lalu otomatis mengunduh alat-alat tempur penting:
   * `stress-ng`: Standar industri untuk menguji ketahanan *hardware* (CPU, Memori, Disk).
   * `iperf3`: Alat pengukur kapasitas *throughput* jaringan TCP/UDP.
   * `apache2-utils` (`ab`): Alat uji beban HTTP konvensional.
   * `wrk`: Alat *benchmarking* HTTP modern berbasis *event-driven* (sangat agresif menghabiskan *socket* web server).
   * `slowhttptest`: Mensimulasikan serangan *Slowloris* untuk menahan *worker connection* Nginx hingga mengalami *timeout*.
3. **Traffic Control (`tc qdisc`)**: Menggunakan modul kernel Linux `netem` (*Network Emulator*) untuk menyisipkan gangguan buatan berupa latensi dan *packet loss* secara langsung pada antarmuka jaringan aktif (*interface* utama yang dideteksi otomatis via `ip route`).
4. **Fungsi Pembersihan (`killall -9`)**: Menghentikan paksa seluruh proses *background* yang berjalan da
