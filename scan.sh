#!/bin/bash

# Cek apakah alat yang diperlukan sudah terinstal
if ! command -v subfinder &>/dev/null; then
    echo "[ERROR] subfinder tidak ditemukan. Silakan instal terlebih dahulu."
    exit 1
fi

if ! command -v httpx &>/dev/null; then
    echo "[ERROR] httpx tidak ditemukan. Silakan instal terlebih dahulu."
    exit 1
fi

if ! command -v yusub &>/dev/null; then
    echo "[ERROR] yusub tidak ditemukan. Silakan instal terlebih dahulu."
    exit 1
fi

# Fungsi untuk menampilkan bantuan
usage() {
    echo "Usage: $0 [-d domain] [-l list] [-o output_file]"
    echo "  -d domain       Satu domain untuk enumerasi subdomain"
    echo "  -l list         File berisi daftar domain"
    echo "  -o output_file  Tentukan file keluaran untuk menyimpan hasil (opsional)"
    exit 1
}

# Parsing argumen
while getopts "d:l:o:" opt; do
    case "$opt" in
    d) DOMAIN=$OPTARG ;;
    l) DOMAIN_LIST=$OPTARG ;;
    o) OUTPUT_FILE=$OPTARG ;;
    *) usage ;;
    esac
done

# Pastikan setidaknya salah satu dari -d atau -l disediakan
if [ -z "$DOMAIN" ] && [ -z "$DOMAIN_LIST" ]; then
    echo "[ERROR] Anda harus menentukan domain (-d) atau daftar domain (-l)."
    usage
fi

# File sementara untuk menyimpan hasil enumerasi
TMP_FILE_SUBFINDER=$(mktemp)
TMP_FILE_YUSUB=$(mktemp)
FINAL_RESULTS=$(mktemp)

# Enumerasi subdomain menggunakan subfinder
if [ -n "$DOMAIN" ]; then
    echo "[INFO] Enumerasi subdomain menggunakan subfinder untuk domain: $DOMAIN"
    subfinder -d "$DOMAIN" -all -recursive -silent > "$TMP_FILE_SUBFINDER"
elif [ -n "$DOMAIN_LIST" ]; then
    echo "[INFO] Enumerasi subdomain menggunakan subfinder untuk daftar domain: $DOMAIN_LIST"
    subfinder -list "$DOMAIN_LIST" -all -recursive -silent > "$TMP_FILE_SUBFINDER"
fi

# Enumerasi subdomain menggunakan yusub
if [ -n "$DOMAIN" ]; then
    echo "[INFO] Enumerasi subdomain menggunakan yusub untuk domain: $DOMAIN"
    echo "$DOMAIN" | yusub > "$TMP_FILE_YUSUB"
elif [ -n "$DOMAIN_LIST" ]; then
    echo "[INFO] Enumerasi subdomain menggunakan yusub untuk daftar domain: $DOMAIN_LIST"
    cat "$DOMAIN_LIST" | yusub > "$TMP_FILE_YUSUB"
fi

# Menggabungkan hasil dari kedua alat
echo "[INFO] Menggabungkan hasil dari subfinder dan yusub..."
cat "$TMP_FILE_SUBFINDER" "$TMP_FILE_YUSUB" | sort -u > "$FINAL_RESULTS"

# Periksa host hidup menggunakan httpx
if [ -s "$FINAL_RESULTS" ]; then
    echo "[INFO] Memeriksa host hidup menggunakan httpx..."
    if [ -n "$OUTPUT_FILE" ]; then
        httpx -sc -title -fr -cname -silent -l "$FINAL_RESULTS" > "$OUTPUT_FILE"
        echo "[INFO] Hasil disimpan ke $OUTPUT_FILE"
    else
        httpx -sc -title -fr -cname -silent -l "$FINAL_RESULTS"
    fi
else
    echo "[ERROR] Tidak ada subdomain yang ditemukan."
fi

# Membersihkan file sementara
rm -f "$TMP_FILE_SUBFINDER" "$TMP_FILE_YUSUB" "$FINAL_RESULTS"
