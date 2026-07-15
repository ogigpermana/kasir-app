# 🏪 Kasir App — Progress Report

## 📋 Info Project
- **Nama**: kasir_app
- **Platform**: Flutter (Android/iOS/Windows)
- **Arsitektur**: Clean Architecture Lite (Domain → Data → Presentation)
- **State Management**: Riverpod
- **Database**: Drift (SQLite) — 7 tables
- **Navigasi**: GoRouter + ShellRoute (bottom nav)

---

## ✅ Fitur Selesai

### Auth & Onboarding
- [x] Login username/password
- [x] Role-based redirect (admin/owner/kasir)
- [x] Onboarding 3 langkah (welcome → nama toko → tipe bisnis)
- [x] Seed default user `admin` / `admin123`

### Produk & Kategori
- [x] CRUD produk (nama, barcode, harga beli/jual, stok, min stok)
- [x] CRUD kategori (hirarki parent-child)
- [x] Auto-generate barcode jika kosong

### Stok
- [x] List stok dengan peringatan stok rendah
- [x] Penyesuaian stok (+/-) dengan alasan
- [x] Riwayat perubahan stok (snapshot before/after)

### Transaksi (POS)
- [x] Grid produk + cart panel
- [x] Quantity control (+/-) di cart
- [x] Toggle PPN
- [x] Pembayaran dengan perhitungan kembalian
- [x] Tampilan receipt setelah bayar

### Laporan
- [x] Ringkasan penjualan (total, jumlah transaksi, rata-rata)
- [x] Filter periode (Hari/Minggu/Bulan/Tahun/Kustom)
- [x] Export CSV → simpan ke **Documents** publik hape (MediaStore)
- [x] Export PDF → simpan ke **Documents** publik hape (MediaStore)
- [x] Tombol "Buka" file langsung dari SnackBar (open_file)

### Pengaturan & Pengguna
- [x] User management CRUD (admin/owner/kasir)
- [x] Role-based navigation (kasir dibatasi)
- [x] Konfigurasi persen pajak
- [x] Logout

### Database
- [x] Migrasi hingga v6 (termasuk hashing password)
- [x] 7 tables: store_settings, users, categories, products, stock_history, transactions, transaction_items

---

## 🚧 Yang Belum / Bisa Dikembangkan

| Prioritas | Fitur | Keterangan |
|-----------|-------|------------|
| 🟡 | **Domain Use Cases** | `domain/usecases/` masih kosong, logic campur di repo/UI |
| 🟡 | **Remote API** | `datasources/remote/` kosong (100% lokal) |
| 🟢 | **Barcode Scanner** | Field barcode ada, tapi belum integrasi scanner |
| 🟢 | **Image Produk** | Field `imagePath` ada, belum ada picker/preview |
| 🟢 | **Diskon Transaksi** | Field `discount` di entity, UI diskon belum ada |
| 🟢 | **Payment Method** | Masih hardcoded `'cash'` |
| 🟢 | **Print Receipt** | Receipt cuma dialog, belum ke thermal printer |
| 🟢 | **Open File Export** | `open_file` dependency ada, belum dipakai |
| 🔴 | **Test Coverage** | Hanya 2 test file (entity test + smoke test) |
| 🔴 | **Reusable Widgets** | `presentation/common/widgets/` kosong |
| 🔴 | **Error Handling** | Perlu sentralisasi error handler |

---

## 📁 Struktur Project

```
lib/
├── main.dart
├── core/                          # Constants, utils, theme
├── data/
│   ├── datasources/local/         # Drift database + generated
│   ├── datasources/remote/        # (kosong)
│   └── repositories/              # RepositoryImpl
├── domain/
│   ├── entities/                  # Product, Category, Transaction dkk
│   ├── repositories/              # Abstract interfaces
│   └── usecases/                  # (kosong)
└── presentation/
    ├── common/providers/          # Riverpod providers
    ├── common/widgets/            # (kosong)
    ├── features/
    │   ├── auth/                  # LoginPage
    │   ├── onboarding/            # OnboardingPage
    │   ├── product/               # ProductListPage, CategoryPage, StockPage
    │   ├── transaction/           # PosPage, ReceiptDialog
    │   ├── report/                # ReportPage
    │   └── settings/              # SettingsPage, UserManagementPage
    └── router.dart
```

---

## 📊 Database Schema (7 Tables)

| Table | Fungsi |
|-------|--------|
| `store_settings` | Key-value config (onboarding, nama toko, tipe bisnis, pajak) |
| `users` | Auth + RBAC (username, password hash, role) |
| `categories` | Kategori produk (self-referencing parentId) |
| `products` | Inventaris produk |
| `stock_history` | Audit trail perubahan stok |
| `transactions` | Transaksi penjualan |
| `transaction_items` | Line items per transaksi |

---

## 🔧 Patch Terakhir

| Tanggal | Patch | Keterangan |
|---------|-------|------------|
| 2026-07-14 | routes: settings selalu tampil | Tab Settings sekarang muncul untuk semua role (kasir bisa logout) |
| 2026-07-14 | produk: kategori parent-child + auto name | Pilih kategori utama → sub kategori → nama produk otomatis dari sub kategori |
| 2026-07-14 | kategori: collapsible children | Child kategori bisa expand/minimize |
| 2026-07-14 | produk: child pake choice chip | Child kategori tampil sebagai chip yang bisa dipilih, bukan dropdown |
| 2026-07-14 | laporan: simpan ke Documents publik | Export PDF/CSV kini disimpan ke folder Documents hape (luar container app) via MediaStore + MethodChannel. SnackBar ada tombol "Buka" |
| 2026-07-14 | produk: fix bug logika edit | initState deteksi parent vs child kategori dengan benar saat edit produk |

---

> **Last updated**: 2026-07-14
> **Guide**: Setiap ada penambahan fitur/patch, file ini akan diupdate.
