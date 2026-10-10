# ArtJagat — Studio Pengeditan Gambar Native macOS

**ArtJagat** adalah aplikasi desktop pengedit gambar native untuk platform macOS (dioptimalkan untuk Apple Silicon). Dibangun menggunakan Swift, SwiftUI, AppKit, Core Graphics, Core Image, dan ImageIO dengan pendekatan *local-first*, modular, dan terstruktur.

---

## 1. Ikhtisar & Tujuan Proyek

ArtJagat dirancang sebagai alternatif editor raster dan grafis desktop dengan alur kerja yang terinspirasi dari standar industri (Photoshop, Affinity Photo, GIMP), namun mempertahankan identitas visual dan ergonomi khas macOS yang bersih, efisien, dan responsif.

- **Bahasa Utama**: Swift 6
- **UI Framework**: SwiftUI + AppKit
- **Rendering & Pemrosesan Citra**: Core Graphics, Core Image (`CIFilter`), ImageIO
- **Arsitektur**: Command Pattern untuk riwayat (Undo/Redo), Reactive State (`ObservableObject` & Combine), Desain Modular tanpa pustaka pihak ketiga eksternal.

---

## 2. Struktur Arsitektur & Direktori

```text
ArtJagat/
├── App/
│   ├── ArtJagatApp.swift           # Entry point aplikasi & deklarasi window
│   ├── AppDelegate.swift           # Siklus hidup AppKit & delegasi menu macOS
│   ├── AppState.swift              # Status global aplikasi (alat aktif, warna, ukuran kuas)
│   ├── ArtJagatCommands.swift      # Menu bar macOS & shortcut keyboard sistem
│   └── WorkspacePreferences.swift  # Pengaturan persistensi via UserDefaults
│
├── Document/
│   ├── ArtDocument.swift           # Model dokumen multi-layer, viewport, & compositing pipeline
│   ├── DocumentManager.swift       # Manajemen banyak dokumen terbuka, buka/tutup/simpan
│   └── SelectionState.swift        # State seleksi piksel (Marquee rectangular, polygon, hit-testing)
│
├── Layers/
│   └── ArtLayer.swift              # Abstraksi layer (raster, shape, text), context bitmap, blend modes, filter CI
│
├── History/
│   └── HistoryManager.swift        # Stack riwayat berbasis Command Pattern (Undo/Redo)
│
├── ImageProcessing/
│   └── ImageExporter.swift         # Pipeline ekspor berkas (PNG, JPEG dengan kompresi, TIFF via ImageIO)
│
└── UI/
    ├── MainWorkspaceView.swift     # Layout utama editor (Split view, tab bar, status bar)
    ├── WelcomeView.swift           # Layar pembuka (buat dokumen baru, buka berkas)
    ├── NewDocumentSheet.swift      # Dialog pembuatan dokumen dengan preset (1080p, 4K, A4, dll)
    ├── DocumentTabBar.swift        # Tab dokumen multi-dokumen dengan indikator dirty state
    ├── StatusBar.swift             # Bilah status (resolusi PPI, dimensi piksel, zoom controls)
    ├── SettingsView.swift          # Jendela preferensi aplikasi (Preferences/Settings)
    ├── Toolbar/
    │   └── ToolbarSidebar.swift    # Bilah alat vertikal sisi kiri & swatch warna
    ├── Canvas/
    │   └── CanvasWorkspace.swift   # Kanvas interaktif (live brush, eraser, move, zoom/pan, grid, marquee)
    └── Panels/
        ├── RightPanelContainer.swift # Wadah panel tab sisi kanan
        ├── LayersPanelView.swift     # Panel manajemen layer (visibilitas, opacity, blend mode)
        ├── AdjustmentsPanelView.swift# Panel filter Core Image (Brightness, Contrast, Noir, Sepia, dll)
        ├── ColorPanelView.swift      # Panel pemilih warna & swatch palet
        └── HistoryPanelView.swift    # Panel riwayat undo/redo
```

---

## 3. Fitur Utama

### 🎨 Sistem Kanvas & Peralatan (Tools)
- **Brush & Eraser Tool**: Menggambar dan menghapus goresan kuas secara langsung ke bitmap layer aktif dengan pengaturan ukuran, opasitas, dan *hardness*.
- **Move Tool**: Menggeser posisi layer secara bebas di atas bidang kanvas.
- **Marquee Selection Tool**: Membuat seleksi persegi dengan visualisasi kontur *marching ants*.
- **Eyedropper Tool**: Mengambil sampel warna langsung dari piksel komposit dokumen.
- **Hand & Zoom Tool**: Navigasi kanvas yang fleksibel dengan kalkulasi koordinat dokumen ke *viewport*, lengkap dengan *checkerboard transparency* dan *pixel grid overlay* pada zoom tinggi ($\ge 400\%$).

### 📑 Sistem Layer & Blending
- Mendukung layer bertipe Raster, Bentuk (Shape), dan Teks.
- Pemilihan *Blend Mode* standar (Normal, Multiply, Screen, Overlay, Darken, Lighten, Hard Light, Soft Light, Difference, Exclusion).
- Pengaturan transparansi/opasitas layer per layer (0–100%).
- Fitur kunci layer (*Lock*), toggle visibilitas (*Eye icon*), duplikasi, penghapusan, serta penyusunan ulang layer.

### ⚡ Pemrosesan Gambar (Core Image)
- Penyesuaian warna secara non-destruktif atau diterapkan ke raster:
  - Brightness, Contrast, Saturation (`CIColorControls`)
  - Filter cepat: Grayscale Noir (`CIPhotoEffectNoir`), Sepia Tone (`CISepiaTone`), Invert Colors (`CIColorInvert`), Vignette (`CIVignette`).

### ↩️ Undo / Redo (Command Pattern)
- Setiap tindakan penting diisolasi ke dalam objek command tersendiri (`PaintStrokeCommand`, `EraseStrokeCommand`, `AddLayerCommand`, `DeleteLayerCommand`, `MoveLayerCommand`).
- Riwayat tindakan ditampilkan di panel riwayat dan dapat diakses bolak-balik menggunakan pintasan keyboard `⌘Z` dan `⇧⌘Z`.

### 💾 Format Berkas & Ekspor
- Membuka berkas gambar standar macOS: PNG, JPEG, TIFF, HEIC.
- Ekspor gambar akhir dengan skala penuh menggunakan ImageIO ke format PNG, JPEG (dengan kualitas kompresi yang dapat diatur), dan TIFF.

---

## 4. Cara Menjalankan Proyek

### Kebutuhan Sistem
- macOS 14.0 (Sonoma) atau lebih baru
- Xcode 15.0+ / Xcode 16.0+ (Swift 6 SDK)
- Mesin berbasis Apple Silicon (M1/M2/M3/M4) atau Intel Mac

### Kompilasi via Terminal
Untuk mengompilasi aplikasi menggunakan `xcodebuild`:

```bash
xcodebuild -project ArtJagat.xcodeproj -scheme ArtJagat -destination 'platform=macOS' build
```

### Menjalankan Aplikasi
Setelah build selesai, binary aplikasi dapat langsung dijalankan:

```bash
open ./DerivedData/ArtJagat-*/Build/Products/Debug/ArtJagat.app
# Atau buka berkas ArtJagat.xcodeproj langsung di Xcode dan tekan ⌘R (Run)
```

---

## 5. Pintasan Keyboard Penting (Shortcuts)

| Pintasan | Tindakan |
|---|---|
| `⌘N` | Buat Dokumen Baru |
| `⌘O` | Buka Berkas Gambar |
| `⌘S` | Simpan Dokumen |
| `⇧⌘S` | Simpan Sebagai (*Save As*) |
| `⇧⌘E` | Ekspor Gambar (*Export*) |
| `⌘W` | Tutup Dokumen Aktif |
| `⌘Z` | Undo |
| `⇧⌘Z` | Redo |
| `⇧⌘N` | Layer Baru |
| `⌘J` | Duplikat Layer |
| `⌘+` | Perbesar Kanvas (*Zoom In*) |
| `⌘-` | Perkecil Kanvas (*Zoom Out*) |
| `⌘0` | Ukuran Piksel Sebenarnya (100%) |
| `⌘'` | Tampilkan / Sembunyikan Grid |
| `⇥` (Tab) | Sembunyikan / Tampilkan Panel Samping |
| `B` | Brush Tool |
| `E` | Eraser Tool |
| `V` | Move Tool |
| `M` | Rectangular Marquee Tool |
| `I` | Eyedropper Tool |
| `H` | Hand Tool |
| `Z` | Zoom Tool |
| `X` | Tukar Warna Foreground / Background |
| `D` | Reset Warna ke Hitam & Putih |
