# Raporlama ve Dışa Aktarma Sistemi Tasarımı (PDF & CSV)

Bu doküman, OkulAsistan uygulamasındaki Nöbet Çizelgeleri ve Kelebek Sınav Dağıtımlarının profesyonel formatta dışa aktarılması için gereken teknik mimariyi tanımlar.

## 1. Kullanılacak Paketler

| Paket | Amaç | Özellikler |
|---|---|---|
| `pdf` | PDF Oluşturma | Düşük seviye kontrol, vektörel çizim, tablo desteği. |
| `printing` | Yazdırma ve Önizleme | Flutter `PdfPreview` widget'ı, yazıcı diyaloğu başlatma. |
| `csv` | CSV Oluşturma | Basit veri dökümü. |
| `path_provider` | Dosya Kaydetme | Cihaz dizinlerine erişim (Mobil/Desktop). |
| `universal_html` | Web Desteği | Web'de dosya indirme tetiklemek için (`AnchorElement`). |

---

## 2. PDF Mimarisi ve Türkçe Karakter Desteği

Standart PDF fontları Türkçe karakterleri (ğ, Ş, İ) desteklemez. Bu nedenle sisteme özel bir TTF fontu (Google Fonts: Roboto veya OpenSans) gömülmelidir.

### Font Yönetimi
```dart
Future<Font> loadFont() async {
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  return Font.ttf(fontData);
}
```

### Sayfa Düzeni (Layout) - A4
Tüm raporlar **A4** boyutunda tasarlanacaktır.
*   **Nöbet Listesi:** Yatay (Landscape) - Geniş tablo sığdırmak için.
*   **Sınav Kağıtları:** Dikey (Portrait) - Kapı asma listeleri için.

---

## 3. Rapor Şablonları

### A. Nöbet Çizelgesi Şablonu
*   **Header:**
    *   Sol: MEB Logosu
    *   Orta: Okul Adı, "Nöbet Çizelgesi" Başlığı, Tarih Aralığı.
*   **Body:**
    *   `pw.Table.fromTextArray` kullanılarak oluşturulur.
    *   Kolonlar: Tarih, Gün, [Nöbet Yerleri...].
    *   Satırlar: Her gün için bir satır.
    *   Haftasonları gri arka plan ile ayrılabilir.
*   **Footer:**
    *   "Okul Müdürü" ve "Müdür Yardımcısı" imza alanları.
    *   Sayfa numarası (Sayfa 1 / 2).

### B. Kelebek Sınav Listesi (Salon Bazlı)
Bu rapor, her salonun kapısına asılacak listeyi üretir.

*   **Sayfa Kırılımı:** Her salon (ExamHall) **yeni bir sayfada** başlamalıdır.
*   **İçerik:**
    *   Büyük başlık: "SALON: 9-A"
    *   Sınav Adı ve Saati.
    *   Oturma Düzeni Tablosu (Sıra No | Ad Soyad | Sınıf).
    *   Gözetmen Öğretmen imza alanı.

### C. Kelebek Sınav Listesi (Öğrenci Bazlı - Pano)
Tüm öğrencilerin hangi salonda gireceğini gösteren alfabetik liste.
*   Çok sayfalı tek bir tablo olarak akar.

---

## 4. Sayfa Kırılımı (Pagination) Kontrolü

`pdf` paketi tabloları otomatik böler, ancak "Salon Bazlı" raporda manuel kırılım gerekir.

```dart
// Her salon için ayrı bir Page widget'ı eklenir (MultiPage yerine)
for (var hall in halls) {
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return Column(
          children: [
             Header(hall.name),
             StudentTable(hall.students),
          ]
        );
      }
    )
  );
}
```

---

## 5. CSV Dışa Aktarma

Excel'de sorunsuz açılması için **UTF-8 BOM** karakteri eklenmelidir.

```dart
String generateCsv(List<List<dynamic>> rows) {
  // UTF-8 BOM (Excel'in Türkçe karakterleri tanıması için şart)
  final bom = '\uFEFF'; 
  final csvContent = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
  return '$bom$csvContent';
}
```
*   Ayraç olarak `;` (noktalı virgül) kullanılmalıdır, çünkü Türkçe Excel varsayılan olarak bunu bekler.

---

## 6. Web ve Mobil Farklılıkları

*   **Mobil:** Dosya `ApplicationDocumentsDirectory` içine kaydedilir ve `OpenResult` ile açılır veya `Share` ile paylaşılır.
*   **Web:** Dosya tarayıcıda Blob olarak oluşturulur ve indirme linki tetiklenir.

## 7. Uygulama Planı

1.  `assets/fonts` klasörü oluştur ve Roboto fontunu ekle.
2.  `pubspec.yaml`'a `pdf`, `printing`, `csv` ekle.
3.  `core/services/pdf_service.dart` servisini oluştur.
4.  `core/services/csv_service.dart` servisini oluştur.
