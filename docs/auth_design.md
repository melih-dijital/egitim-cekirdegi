# Supabase Auth Tasarımı ve Entegrasyon Planı

Bu belge, "OkulAsistan" uygulaması için Admin ve Öğretmen rollerine özel hibrit bir kimlik doğrulama mimarisini tanımlar.

## 1. Mimari Genel Bakış

Sistem iki farklı giriş yöntemi kullanacaktır:
1.  **Standart Auth (Yöneticiler):** Klasik E-posta/Şifre ve OAuth (Google/Apple) sağlayıcıları.
2.  **Özel Kod Auth (Öğretmenler):** Arka planda "Shadow Accounts" (Gölge Hesaplar) kullanan 6 haneli kod sistemi.

### Mantıksal Akış Diyagramı

```mermaid
graph TD
    A[Uygulama Açılışı] --> B{Kullanıcı Tipi?}
    
    %% YÖNETİCİ AKIŞI
    B -- Yönetici --> C[Giriş Ekranı]
    C --> D{Yöntem?}
    D -- Email/Pass --> E[Supabase Auth (SignIn)]
    D -- OAuth --> F[Social Provider (Google/Apple)]
    E --> G[Dashboard]
    F --> G
    
    %% ÖĞRETMEN AKIŞI
    B -- Öğretmen --> H[Kod Giriş Ekranı]
    H --> I[6 Haneli Kod Girilir: '123456']
    I --> J[App Arkada Dönüştürür: '123456@temp.okul']
    J --> K[Supabase Auth (SignInWithPassword)]
    K --> L{Başarılı mı?}
    L -- Hayır --> M[Hata: Geçersiz Kod]
    L -- Evet --> N[Dashboard (Öğretmen Modu)]
    
    %% SONRADAN MAİL BAĞLAMA
    N --> O[Ayarlar -> Hesabı Bağla]
    O --> P[Yeni E-posta ve Şifre Gir]
    P --> R[Supabase: updateUser(email)]
    R --> S[E-posta Doğrulama]
    S --> T[Kod İptal Edilir / Hesap Kalıcı Olur]
```

---

## 2. Öğretmen "Kod ile Giriş" Mekanizması (Shadow Accounts)

Supabase native olarak sadece "kod" ile giriş desteklemez. Bunu aşmak için **"Pseudo-Email" (Sahte E-posta)** deseni kullanacağız.

### Nasıl Çalışır?
1.  **Hesap Oluşturma (Admin Paneli):**
    *   Yönetici bir öğretmen eklediğinde (örneğin Ali Veli), arka planda bir Cloud Function veya Admin işlemi çalışır.
    *   Sistem rastgele 6 haneli bir kod üretir: `849201`.
    *   Supabase Auth üzerinde şu kullanıcıyı oluşturur:
        *   **Email:** `849201@temp.okulasistan.com`
        *   **Password:** `849201` (veya sistem tarafından belirlenen sabit bir salt ile hashlenmiş versiyonu).
        *   **User Metadata:** `{ "is_temp": true, "role": "teacher" }`
    
2.  **Giriş Yapma (Flutter):**
    *   Öğretmen sadece `849201` yazar.
    *   Flutter uygulaması bunu `849201@temp.okulasistan.com` adresine tamamlar ve şifre olarak kodu gönderir.
    *   Giriş başarılı olursa oturum açılır.

3.  **Hesap Bağlama (Dönüştürme):**
    *   Öğretmen giriş yaptıktan sonra, `UserAttributes` güncellemesi ile "temp" e-postasını kendi gerçek e-postasıyla (örn: `ali@meb.gov.tr`) değiştirir.
    *   Bu aşamadan sonra 6 haneli kod geçersiz olur, öğretmen kendi belirlediği şifre ve mail ile girer.

---

## 3. Güvenlik Önlemleri

### A. Brute-Force Koruması
6 haneli kodlar (1.000.000 ihtimal) deneme-yanılma saldırılarına açıktır.
*   **Supabase Rate Limiting:** Supabase varsayılan olarak bir IP'den gelen başarısız giriş denemelerini (örneğin saatte 5) sınırlar. Bu özellik **mutlaka aktif** olmalıdır.
*   **Captcha:** 3 başarısız denemeden sonra Captcha gösterilmesi arayüz tarafında zorlanmalıdır.

### B. Row Level Security (RLS)
Veritabanı seviyesinde izolasyon şarttır.
*   **Teachers Tablosu:**
    ```sql
    CREATE POLICY "Teachers can update own data" ON teachers
    FOR UPDATE USING (auth.uid() = user_id);
    ```
*   **Public Erişim Yasağı:** Kodların veya kullanıcı listesinin `anon` rolü tarafından okunması engellenmelidir.

### C. Kod Yönetimi
*   Kodlar tahmin edilebilir olmamalı (`SecureRandom` kullanılmalı).
*   Mail bağlandıktan sonra sistemdeki "Gölge E-posta" silinmiş olur, böylece kod tekrar kullanılamaz.

---

## 4. Token & Session Yönetimi

Supabase standart JWT (JSON Web Token) yapısını kullanır.

*   **Access Token:** Kısa ömürlüdür (örn. 1 saat). API isteklerinde `Authorization: Bearer <token>` başlığı ile gönderilir.
*   **Refresh Token:** Uzun ömürlüdür. Access token süresi dolunca arka planda (kullanıcı hissetmeden) yeni token almak için kullanılır.
*   **Flutter Entegrasyonu:** `supabase_flutter` paketi bu döngüyü otomatik yönetir (`autoRefreshToken: true`).
*   **Persistency:** Oturum bilgileri cihazın güvenli depolama alanında (`SharedPreferences` / `Keychain`) saklanır. Uygulama kapatılıp açılınca giriş yapılı kalır.

---

## 5. Flutter Tarafı Uygulama (Kod Örnekleri)

Bu yapıları `AuthRepository` içine entegre edeceğiz.

### A. Giriş Fonksiyonu (Hybrid)

```dart
Future<Either<Failure, void>> login({
  required String identifier, // Email veya 6 haneli kod
  String? password, // Kod ile girişte null olabilir
}) async {
  try {
    String email;
    String finalPassword;

    // 6 Haneli Kod Kontrolü (Regex: Sadece rakam ve 6 hane)
    final isSixDigitCode = RegExp(r'^\d{6}$').hasMatch(identifier);

    if (isSixDigitCode) {
      // Gölge Hesap Mantığı
      email = '$identifier@temp.okulasistan.com';
      finalPassword = identifier; // Şifre kodun kendisidir
    } else {
      // Standart Giriş
      email = identifier;
      finalPassword = password!;
    }

    await supabase.auth.signInWithPassword(
      email: email,
      password: finalPassword,
    );

    return right(null);
  } on AuthException catch (e) {
    return left(AuthFailure(e.message));
  } catch (e) {
    return left(AuthFailure('Giriş başarısız: $e'));
  }
}
```

### B. E-posta Bağlama (Hesap Dönüştürme)

```dart
Future<Either<Failure, void>> linkEmail({
  required String newEmail,
  required String newPassword,
}) async {
  try {
    final UserAttributes attrs = UserAttributes(
      email: newEmail,
      password: newPassword,
    );
    
    // Mevcut (kod ile girmiş) kullanıcının bilgilerini güncelle
    await supabase.auth.updateUser(attrs);
    
    return right(null);
  } catch (e) {
    return left(AuthFailure('Hesap bağlama hatası: $e'));
  }
}
```

### C. OAuth (Yöneticiler İçin)

```dart
Future<void> signInWithGoogle() async {
  await supabase.auth.signInWithOAuth(
    Provider.google,
    redirectTo: 'io.supabase.okulcekirdegi://login-callback',
  );
}
```
