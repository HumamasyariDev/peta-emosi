# Peta Emosi: Petualangan Taman Emosi

Game edukasi 3D bergaya storybook yang dibangun dengan **Godot 4.7** untuk membantu anak usia 6–12 tahun mengenal 6 emosi dasar, mengelola amarah secara sehat, dan melatih empati melalui 8 Pos interaktif.

- **Demo Web Live**: https://peta-emosi.vercel.app

## Daftar 8 Pos Petualangan

1. **Pos 1: Gerbang Pengenalan** - Cerita pembuka interaktif Nara & Papan Rahasia Emosi (Daniel Goleman, 2022).
2. **Pos 2: Taman 6 Emosi Dasar** - Bertemu dan mengumpulkan stempel 6 emosi dasar (Sedih, Marah, Takut, Bahagia, Jijik, Terkejut).
3. **Pos 3: Bukit Lonceng Emas** - Membunyikan Lonceng Eling & mini-game keseimbangan emosi negatif.
4. **Pos 4: 6 Langkah Menenangkan Diri** - Praktik 3D berhenti, menahan tangan, meniup kincir napas, melompati batu sungai 1-10, bersantai di gazebo bersama kucing oranye, dan menjauh sejenak.
5. **Pos 5: Ekspresikan Marah Dengan Sehat** - Memukul bantal awan empuk, merobek kertas bekas ke keranjang daur ulang, dan memilih cara penyaluran aman.
6. **Pos 6: Saat Melihat Teman Marah** - Melatih empati terhadap kebutuhan berbeda Bima (main bareng menyusun balok) dan Sinta (waktu tenang & air sejuk).
7. **Pos 7: Prinsip Saat Marah** - 3 pulau aksi nyata (jangan sakiti diri sendiri, jangan sakiti orang lain, jangan merusak barang) lengkap dengan jembatan rintangan lompat kayu amarah.
8. **Pos 8: Finish: Aku Tahu Emosiku!** - Menyalakan 3 Lentera Kenangan Emosi, mengangkat Piala Emas di podium perayaan, dan menerima Piagam Penjelajah Taman Emosi.

## Fitur Utama

- **Visual 3D Storybook HD**: Toon shader dengan ink outline, langit awan painterly, HiDPI, 4x MSAA, 16x Anisotropic Filtering, dan bayangan halus yang dikalibrasi khusus untuk Desktop maupun WebGL2.
- **Narasi Suara Bahasa Indonesia + Subtitle Tersinkronisasi**: Dilengkapi tombol ulangi audio, bilah durasi langsung, dan transisi musik latar otomatis.
- **Auto-Save Progres**: Menyimpan bintang, koin, dan stempel emosi secara otomatis (`localStorage` di Web dan `user://peta_emosi_save.json` di Desktop).
- **Dukungan Desktop & Mobile Landscape**: Kontrol `WASD`/Panah + `Spasi` + `E` + `M` di Desktop, serta joystick analog 360 derajat dan tombol aksi/lompat di layar sentuh.

## Cara Menjalankan di Godot 4.7

1. Buka **Godot 4.7**, klik **Import**, lalu pilih `project.godot`.
2. Tekan **F5** untuk memulai dari `scenes/boot/Boot.tscn`.

## Export Web

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```
