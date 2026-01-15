# Nöbet Planlama Algoritması Tasarımı

Bu doküman, "OkulAsistan" uygulaması için adil, çakışmasız ve dengeli bir nöbet dağıtım algoritmasını tanımlar.

## 1. Hedefler ve Kısıtlamalar

### Temel Hedefler
1.  **Adalet (Fairness):** Seçilen tarih aralığında her öğretmene mümkün olduğunca eşit sayıda nöbet yazılmalıdır.
2.  **Çeşitlilik (Variety):** Bir öğretmen sürekli aynı yerde nöbet tutmamalıdır.
3.  **Uygunluk (Availability):** Öğretmenin raporlu veya izinli olduğu günlere nöbet yazılmamalıdır.

### Kısıtlamalar (Hard Constraints)
*   Bir öğretmene aynı gün içinde birden fazla nöbet yazılamaz.
*   Öğretmen mevcut değilse (izinli) nöbet yazılamaz.

### Tercihler (Soft Constraints)
*   Mümkünse, bir öğretmen dün "Bahçe"de nöbet tuttuysa, bugün tekrar "Bahçe"ye yazılmasın.
*   Nöbet günleri mümkün olduğunca haftaya yayılmalı (örn: hep Pazartesi olmasın).

---

## 2. Algoritma Mantığı: "Ağırlıklı Açgözlü Seçim" (Weighted Greedy Selection)

Bu problem bir **Kısıt Karşılama Problemi (CSP)** türevidir. Ancak tam kapsamlı bir backtracking (Geri İzleme) yerine, çoğu okul senaryosu için yeterli olan ve daha hızlı çalışan **Heuristic Greedy** (Sezgisel Açgözlü) yöntemi kullanılacaktır.

### Veri Yapıları
*   `Map<TeacherId, int> dutyCounts`: Her öğretmenin toplam nöbet sayısı.
*   `Map<TeacherId, String> lastArea`: Öğretmenin en son görev aldığı yer.
*   `Map<Date, List<TeacherId>> dailyAssignments`: O gün atanmış öğretmenler listesi.

---

## 3. Pseudo-Code

```plaintext
FUNCTION GenerateDutyPlan(StartDate, EndDate, Teachers, Areas):
    Plan = []
    DutyCounts = {Teacher: 0}
    LastArea = {Teacher: NULL}

    # Tarih aralığındaki her gün için dön
    FOR Day FROM StartDate TO EndDate:
        
        # O gün nöbet tutulacak mı? (Haftasonu kontrolü)
        IF IsWeekend(Day) CONTINUE
        
        DailyAssigned = []
        Shuffle(Areas) # Bölgeleri karıştır (böylece hep aynı bölge ilk dolmaz)

        FOR Area IN Areas:
            # 1. Aday Havuzu Oluştur
            Candidates = All Teachers
            
            # 2. Filtreleme (Hard Constraints)
            Candidates = Filter(Candidates WHERE:
                Teacher is Available on Day AND
                Teacher NOT IN DailyAssigned
            )
            
            IF Candidates IS EMPTY:
                LogWarning("Yeterli öğretmen yok: $Day - $Area")
                CONTINUE

            # 3. Puanlama ve Sıralama (Soft Constraints & Fairness)
            ScoreMap = {}
            FOR Teacher IN Candidates:
                Score = 0
                
                # Kriter A: Toplam nöbet sayısı (Daha az olan öncelikli)
                # Maksimum puandan mevcut nöbet sayısını çıkararak az olana yüksek puan ver
                Score += (1000 - DutyCounts[Teacher]) * 10 
                
                # Kriter B: Aynı yer tekrarı
                IF LastArea[Teacher] == Area:
                    Score -= 500 # Ciddi ceza puanı
                
                ScoreMap[Teacher] = Score

            # 4. Seçim
            # Puanı en yüksek olanı seç, eşitlikte rastgele davran
            SelectedTeacher = GetHighestScore(ScoreMap)

            # 5. Atama Yap
            Plan.add(Duty(Day, Area, SelectedTeacher))
            DutyCounts[SelectedTeacher]++
            LastArea[SelectedTeacher] = Area
            DailyAssigned.add(SelectedTeacher)

    RETURN Plan
```

---

## 4. Zor Durum Senaryoları (Corner Cases)

### A. Senaryo: Öğretmen Sayısı < Bölge Sayısı
*   **Sorun:** Bir günde nöbet tutacak yeterli öğretmen yok.
*   **Çözüm:** Algoritma o gün için doldurabildiği kadar bölgeyi doldurur ve boş kalanlar için `Unassigned` (Atanmamış) kaydı oluşturur. Kullanıcı arayüzünde bu alanlar kırmızı ile gösterilir.

### B. Senaryo: Çok Fazla Kısıtlama (İzinler)
*   **Sorun:** Bir öğretmenin çok fazla günü kapalıysa, adil dağıtım imkansızlaşır.
*   **Çözüm:** Algoritma "Adalet" kuralını esnetir. Diğer öğretmenlere daha fazla nöbet yazar. Rapor ekranında "X öğretmeni kısıtlamalar nedeniyle az nöbet aldı" uyarısı gösterilir.

---

## 5. Performans Değerlendirmesi

*   **Zaman Karmaşıklığı:** O(G * B * Ö)
    *   G: Gün Sayısı (örn: 20 iş günü)
    *   B: Bölge Sayısı (örn: 5 bölge)
    *   Ö: Öğretmen Sayısı (örn: 40 öğretmen)
    *   *Tahmini:* 20 * 5 * 40 = 4000 iterasyon. Modern mobil cihazlarda < 50ms sürer.
*   **Bellek:** Çok düşüktür. Sadece üretilen plan listesi tutulur.

## 6. Dart Uygulama Önerisi

Bu algoritma `features/duty_planning/domain/logic/duty_distributor.dart` dosyasında izole bir sınıf olarak yazılmalıdır. `Isolate` kullanmaya gerek yoktur çünkü işlem hacmi küçüktür.

```dart
class DutyDistributor {
  List<Duty> distribute({
    required DateTime start,
    required DateTime end,
    required List<Teacher> teachers,
    required List<String> areas,
  }) {
     // ... implementation
  }
}
```
