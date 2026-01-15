# Excel & CSV Dosya Yükleme Sistemi Tasarımı

Bu doküman, OkulAsistan uygulamasında Öğrenci ve Öğretmen listelerinin toplu içe aktarılması (Bulk Import) için kullanılacak mimariyi tanımlar.

## 1. Kullanılacak Paketler

| Paket | Amaç | Neden? |
|---|---|---|
| `file_picker` | Dosya seçimi | Platformlar arası (Mobil/Web/Desktop) en kararlı çözüm. |
| `excel` | .xlsx okuma | Dart native olduğu için hafiftir. |
| `csv` | .csv okuma | Standart CSV formatlarını destekler. |
| `uuid` | Dosya isimlendirme | Benzersiz dosya isimleri için. |

---

## 2. İş Akışı (Workflow)

```mermaid
graph TD
    A[Kullanıcı Dosya Seçer] --> B{Validasyon}
    B -- Geçersiz --> C[Hata Göster]
    B -- Geçerli --> D[Dosya Okuma (Parse)]
    D --> E[Şema Kontrolü (Headerlar)]
    E --> F[Hatalı Satır Kontrolü]
    F --> G{Hata Var mı?}
    G -- Evet --> H[Hata Raporu Göster]
    G -- Hayır --> I[Önizleme Tablosu]
    I --> J[Onayla & Yükle]
    J --> K[Supabase Storage'a Yükle]
    K --> L[Veritabanına Yaz (Batch Insert)]
```

---

## 3. Validasyon Kuralları

1.  **Dosya Uzantısı:** Sadece `.xlsx`, `.xls`, `.csv`.
2.  **Dosya Boyutu:** Maksimum 5MB (Çoğu öğrenci listesi 100KB'ı geçmez).
3.  **Şema (Header) Kontrolü:** İlk satırın beklenen kolon isimlerini içerip içermediği kontrol edilir.
    *   *Örnek Beklenen:* `Okul No`, `Ad Soyad`, `Sınıf`, `Şube`
    *   *Algorithm:* Levenshtein Distance (Opsiyonel) ile küçük yazım hataları ("Sinif" vs "Sınıf") tolere edilebilir veya katı eşitlik aranır.

---

## 4. Hatalı Veri Yönetimi

Yükleme sırasında tüm dosyanın reddedilmesi yerine, **"Kısmi Başarı"** prensibi uygulanacaktır.

*   **Validasyon Sonucu Objesi:**
    ```dart
    class ImportResult<T> {
      final List<T> validRows;
      final List<ImportError> errors;
      
      bool get hasErrors => errors.isNotEmpty;
    }
    
    class ImportError {
      final int rowIndex;
      final String message; // Örn: "Satır 4: Okul numarası boş olamaz."
      final Map<String, dynamic> rawData;
    }
    ```

*   **Kullanıcı Arayüzü:**
    Hatalı satırlar kırmızı ile işaretlenip, kullanıcıya "Hatalıları atla ve devam et" veya "Dosyayı düzeltip tekrar yükle" seçeneği sunulur.

---

## 5. Supabase Storage Entegrasyonu

Dosyalar işlendikten sonra, **orijinal dosyanın** yedeği veya işlenme kanıtı olarak Supabase Storage'da saklanması önerilir.

*   **Bucket:** `raw_imports`
*   **Path Yapısı:** `{school_id}/{type}/{year}/{month}/{timestamp}_{uuid}.xlsx`
    *   `type`: `students` | `teachers` | `exam_results`
*   **RLS:** Sadece yetkili öğretmenler/yöneticiler `insert` ve `select` yapabilir.

---

## 6. Performans (Büyük Dosyalar)

Mobil cihazlarda ana thread'i (UI) bloklamamak için dosya okuma işlemi **Isolate** (Arka plan işçisi) üzerinde yapılmalıdır.

*   **Excel Parsing:** `.xlsx` dosyaları XML tabanlı olduğu için parse edilmesi işlemciyi yorar. 1000+ satırlık dosyalar için `compute()` fonksiyonu kullanılacaktır.
    ```dart
    // Örnek Isolate kullanımı
    final result = await compute(parseExcelBytes, fileBytes);
    ```

---

## 7. Veri Modeli ve Mapping

Her yükleme türü için bir `ImportDefinition` tanımlanır.

### Örnek: Öğrenci Yükleme Tanımı
*   **Zorunlu Kolonlar:** `no`, `ad_soyad`, `sinif`
*   **Opsiyonel Kolonlar:** `sube`, `cinsiyet`
*   **Map Fonksiyonu:** Excel satırını `Student` objesine çeviren fonksiyon.

---

## 8. Güvenlik Notları

*   **Zararlı İçerik:** Dosyalar sunucuda çalıştırılmayacağı (sadece blob olarak saklanacağı ve client-side parse edileceği) için XSS veya RCE riski düşüktür.
*   **Kota:** Okul başına aylık yükleme kotası veya depolama kotası uygulanabilir.
