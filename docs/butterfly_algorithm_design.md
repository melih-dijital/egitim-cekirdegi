# Kelebek Sınav Dağıtım Algoritması Tasarımı

Bu doküman, farklı sınıf düzeyindeki öğrencilerin (9, 10, 11, 12) sınav salonlarına birbirlerinin kağıdını göremeyecek şekilde (Kelebek Sistemi) dağıtılmasını sağlayan algoritmayı tanımlar.

## 1. Problem Tanımı

### Kısıtlamalar
1.  **Yan Yana Kısıtı (Side-by-side):** Aynı sırada yan yana oturan öğrenciler **asla** aynı sınıf düzeyinden (Grade) olmamalıdır.
    *   *Örn:* 9. Sınıf'ın yanına 9. Sınıf oturamaz.
2.  **Kapsama:** Sınava girecek tüm öğrenciler yerleştirilmelidir.
3.  **Kapasite:** Salonların toplam kapasitesi öğrenci sayısını karşılamalıdır.

### Girdiler
*   `List<Student> students`: Sınıf düzeyi (`grade`) bilgisini içerir.
*   `List<ExamHall> halls`: Kapasite ve sıra düzeni (`columns`) bilgisini içerir.

---

## 2. Algoritma Stratejisi: "Çoklu Kuyruk & Öncelikli Dağıtım"

Bu algoritma, her sınıf düzeyi için bir kuyruk oluşturur ve her koltuğa, komşularıyla çakışmayacak **en kalabalık** gruptan öğrenci atar.

### Adım 1: Hazırlık
*   Salonlar sanal bir "Sıra Listesi"ne dönüştürülür. Her sıra için koordinat (`HallId, Row, Column`) belirlenir.
*   Öğrenciler sınıf düzeylerine göre gruplanır:
    *   `Map<Grade, Queue<Student>> studentQueues`
*   Toplam kapasite kontrolü yapılır. Yetersizse işlem durdurulur.

### Adım 2: Dağıtım Döngüsü (Greedy Approach)

```plaintext
Her Salon (Hall) İçin:
  Her Koltuk (Seat) İçin (Soldan Sağa, Önden Arkaya):
    
    1. Komşu Kontrolü:
       - Solundaki koltukta kim var? -> LeftGrade
       - (Opsiyonel) Önündeki koltukta kim var? -> FrontGrade
    
    2. Yasaklı Liste Oluştur:
       - BanList = [LeftGrade]
    
    3. Aday Belirleme:
       - Kuyrukları tara.
       - BanList'te OLMAYAN ve EN ÇOK öğrencisi kalan sınıfı seç.
       - Aday Sınıf = Grade with Max(Count) where Grade NOT IN BanList
    
    4. Atama:
       - Eğer uygun aday varsa:
         - Öğrenciyi kuyruktan al -> Koltuğa ata.
         - Seat.Grade = Student.Grade
       
       - Eğer uygun aday YOKSA (Tıkanıklık):
         - Strateji A (Boş Bırak): Kapasite fazlası varsa koltuğu boş geç.
         - Strateji B (Zorunlu Atama): Kuralı ihlal et ama "Çakışma" olarak işaretle.
         - Strateji C (Backtracking): Bir önceki adımlara dönüp değiştirmeyi dene (Karmaşık).
         *Biz Strateji B'yi kullanacağız (Raporlarda uyarı göster).*
```

---

## 3. Akıllı Sıralama (Heuristic Optimization)

Tıkanıklıkları önlemek için dağıtıma başlamadan önce "Dominant Sınıf" analizi yapılır.

*   Eğer bir sınıfın mevcudu, toplam mevcudun %50'sinden fazlaysa, algoritma o sınıfı önceliklendirecek "Özel Desen" moduna geçer.
*   **Desen:** `A - X - A - Y - A - Z` (A: Dominant sınıf).

---

## 4. Örnek Senaryo

**Veri:**
*   9. Sınıf: 20 Öğrenci
*   10. Sınıf: 10 Öğrenci
*   11. Sınıf: 10 Öğrenci
*   Salon: 20 Kişilik (2 Sütun x 10 Sıra)

**İşleyiş:**
1.  **Koltuk 1 (Sol):** En kalabalık grup 9. Sınıf -> **9** Yerleşti. (Kalan: 19, 10, 10)
2.  **Koltuk 2 (Sağ):** Sol komşu 9. Sınıf. 9 Yasaklı. En kalabalık diğerleri 10 veya 11. -> **10** Yerleşti. (Kalan: 19, 9, 10)
3.  **Koltuk 3 (Alt Sol):** Üst komşu (Ön) kısıtı yoksa, yine en kalabalık 9. -> **9** Yerleşti.
4.  **Koltuk 4 (Alt Sağ):** Sol komşu 9. -> **11** Yerleşti.

**Sonuç:** `9-10`, `9-11`, `9-10`, `9-11`... deseni kendiliğinden oluşur.

---

## 5. Veri Yapıları (Dart)

### `ExamPlacement`
Veritabanına da kaydedilecek nihai sonuç objesi.

```dart
class ExamPlacement {
  final String studentId;
  final String classroomId;
  final int seatNumber; // 1'den başlar, soldan sağa artar
  final String studentGrade; // Kural kontrolü için cache
}
```

### `DistributionConfig`
Algoritma parametreleri.

```dart
class DistributionConfig {
  final bool preventSideBySide; // Varsayılan: true
  final bool preventFrontBack; // Varsayılan: false (Daha sıkı kısıt)
  final bool fillEmptySeats; // Kapasite fazlaysa aralara boşluk koy
}
```

---

## 6. Zor Durumlar (Edge Cases)

### A. Tek Sınıfın Aşırı Fazlalığı
*   *Durum:* 100 öğrencinin 80'i 9. sınıf.
*   *Sonuç:* Algoritma bir süre sonra 9-9-9 koymak zorunda kalır.
*   *Çözüm:* Kullanıcıya "Dağıtım tamamlandı ancak 15 çakışma var" uyarısı gösterilir.

### B. Tek Sütunlu Salonlar
*   *Durum:* Salon çok dar.
*   *Çözüm:* "Yan yana" kısıtı anlamsızlaşır, "Ön-Arka" kısıtı devreye girmelidir. Algoritma salonun `columnCount` değerine göre dinamik davranmalıdır.
