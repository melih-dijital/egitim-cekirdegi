# Supabase (PostgreSQL) Veritabanı Tasarımı

Bu doküman, OkulAsistan uygulaması için önerilen veritabanı şemasını, ilişkileri ve güvenlik politikalarını içerir.

## 1. Genel Bakış ve Varsayımlar
- **Auth**: Supabase'in yerleşik `auth.users` tablosu kimlik doğrulama için kullanılacaktır.
- **Multi-Tenancy**: Birden fazla okulun sistemi kullanabileceği varsayılarak çoğu tabloya `school_id` eklenmiştir (Opsiyonel).
- **ID Yapısı**: Güvenlik ve ölçeklenebilirlik için tüm Primary Key'lerde `UUID` kullanılacaktır.

---

## 2. Tablo Tanımları

### A. `public.users` (Kullanıcı Profilleri)
`auth.users` tablosunu tamamlayan, uygulama içi kullanıcı bilgilerini tutar.
*Her kayıt olma işleminden sonra tetikleyici (trigger) ile oluşturulması önerilir.*

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, FK (`auth.users.id`) | Supabase Auth ID ile birebir eşleşir. |
| `full_name` | `text` | NOT NULL | Kullanıcının tam adı. |
| `role_id` | `text` | FK (`roles.name`) | Kullanıcı rolü (admin, teacher, student). |
| `school_id` | `uuid` | Index | Bağlı olduğu okul ID'si. |
| `avatar_url` | `text` | | Profil fotoğrafı linki. |
| `created_at` | `timestamptz` | DEFAULT `now()` | Kayıt tarihi. |

**İlişkiler**:
- `id` -> `auth.users(id)` (Delete CASCADE)
- `role_id` -> `roles(name)`

**RLS Politikaları**:
- Kullanıcı kendi profilini görebilir ve düzenleyebilir.
- Adminler tüm profilleri görebilir.

---

### B. `public.roles` (Roller)
Sistemdeki yetki gruplarını tanımlar.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `name` | `text` | PK | Rol adı ('admin', 'teacher', 'student'). |
| `description` | `text` | | Rolün açıklaması. |

**Varsayılan Veriler**: `admin`, `teacher`, `student`.

---

### C. `public.invite_codes` (Davet Kodları)
Öğretmenlerin uygulamaya kayıt olurken yetkilendirilmesi için kullanılan 6 haneli kodlar.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Kayıt ID. |
| `code` | `text` | UNIQUE, NOT NULL | 6 haneli davet kodu. |
| `teacher_id` | `uuid` | FK (`teachers.id`) | Bu kod hangi öğretmen için oluşturuldu? |
| `role_id` | `text` | FK (`roles.name`) | Atanacak rol (genelde 'teacher'). |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `is_used` | `boolean` | DEFAULT `false` | Kod kullanıldı mı? |
| `expires_at` | `timestamptz` | NOT NULL | Kodun geçerlilik süresi. |

**Indexler**: `code`

**RLS**: Sadece Adminler oluşturabilir ve görüntüleyebilir. Public okuma (kod doğrulama için) özel fonksiyon ile sınırlandırılabilir.

---

### D. `public.teachers` (Öğretmenler)
Okuldaki öğretmen kadrosu. Kullanıcı hesabı olmasa bile listede var olabilirler.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Öğretmen ID. |
| `user_id` | `uuid` | FK (`users.id`), Nullable | Eğer öğretmen kayıt olmuşsa kullanıcı ID'si buraya linklenir. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `full_name` | `text` | NOT NULL | Görünen isim. |
| `branch` | `text` | NOT NULL | Branş (Matematik, Fizik vb.). |
| `email` | `text` | | İletişim e-postası. |
| `phone` | `text` | | Telefon numarası. |

**RLS**:
- Adminler tam yetkili (CRUD).
- Öğretmenler kendi verilerini güncelleyebilir (`user_id` eşleşmesi ile).

---

### E. `public.classes` (Sınıflar/Şubeler)
Okuldaki şubeler (Örn: 9-A, 10-B).

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Sınıf ID. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `grade` | `int` | NOT NULL | Sınıf seviyesi (9, 10, 11, 12). |
| `branch` | `text` | NOT NULL | Şube (A, B, C). |
| `name` | `text` | Generated | Örn: "9-A" (Sanal kolon veya client-side). |

**Indexler**: `school_id`, `grade`, `branch` (Composite UNIQUE)

---

### F. `public.students` (Öğrenciler)
Kelebek sistemi için öğrenci veritabanı.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Öğrenci ID. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `student_number` | `text` | NOT NULL | Okul numarası. |
| `full_name` | `text` | NOT NULL | Ad Soyad. |
| `class_id` | `uuid` | FK (`classes.id`) | Sınıfı. |
| `gender` | `text` | | Cinsiyet (Kız/Erkek - Dağıtım algoritmaları için gerekebilir). |

**Indexler**: `student_number`, `class_id`

---

### G. `public.classrooms` (Derslikler / Sınav Salonları)
Sınavların yapılacağı fiziksel mekanlar.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Salon ID. |
| `name` | `text` | NOT NULL | Salon Adı (Örn: 9-A Sınıfı, Z-Kütüphane). |
| `capacity` | `int` | NOT NULL | Kapasite. |
| `column_count` | `int` | DEFAULT 4 | Sıra düzenindeki sütun sayısı. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |

---

### H. `public.duty_plans` (Nöbet Çizelgesi)
Hangi tarihte, hangi öğretmenin, nerede nöbetçi olduğu.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Nöbet ID. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `date` | `date` | NOT NULL | Nöbet tarihi. |
| `area` | `text` | NOT NULL | Nöbet yeri (Bahçe, Koridor vb.). |
| `teacher_id` | `uuid` | FK (`teachers.id`) | Nöbetçi öğretmen. |
| `created_at` | `timestamptz` | DEFAULT `now()` | Oluşturulma zamanı. |

**Indexler**: `date`, `teacher_id`

---

### I. `public.exam_plans` (Kelebek Sınav Planları)
Bir sınav oturumunun (Senaryo) üst kaydı.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Sınav Plan ID. |
| `school_id` | `uuid` | NOT NULL | Okul ID. |
| `name` | `text` | NOT NULL | Sınav Adı (Örn: 1. Dönem 1. Yazılılar). |
| `date` | `timestamptz` | NOT NULL | Sınav tarihi ve saati. |
| `status` | `text` | DEFAULT 'draft' | Durum (draft, published, completed). |

### J. `public.exam_placements` (Sınav Yerleşimleri - Detay Tablo)
Kelebek algoritması sonucunda hangi öğrencinin nerede oturacağını tutar.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Yerleşim ID. |
| `exam_plan_id` | `uuid` | FK (`exam_plans.id`) | Hangi sınav planı? |
| `student_id` | `uuid` | FK (`students.id`) | Öğrenci kim? |
| `classroom_id` | `uuid` | FK (`classrooms.id`) | Hangi salonda? |
| `seat_number` | `int` | NOT NULL | Sıra numarası. |

**Indexler**: `exam_plan_id`, `classroom_id`

---

### K. `public.notifications` (Bildirimler)
Uygulama içi bildirimler.

| Alan | Veri Tipi | Kısıtlamalar | Açıklama |
|---|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` | Bildirim ID. |
| `user_id` | `uuid` | FK (`users.id`) | Kime gönderildi? |
| `title` | `text` | NOT NULL | Başlık. |
| `message` | `text` | NOT NULL | İçerik. |
| `type` | `text` | DEFAULT 'info' | Bildirim tipi (duty_alert, exam_info). |
| `is_read` | `boolean` | DEFAULT `false` | Okundu mu? |
| `created_at` | `timestamptz` | DEFAULT `now()` | Gönderim zamanı. |

**RLS**:
- Kullanıcılar sadece kendi bildirimlerini görebilir (`user_id = auth.uid()`).
- Sistem servisleri veya Adminler herkese bildirim oluşturabilir.

---

## 3. SQL Kurulum Scripti (Özet)

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ROLES
create table public.roles (
  name text primary key,
  description text
);
insert into public.roles (name) values ('admin'), ('teacher'), ('student');

-- PROFILES / USERS
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  role_id text references public.roles(name) default 'teacher',
  school_id uuid, -- Assuming separate schools table exists or just an ID
  created_at timestamptz default now()
);

-- TEACHERS
create table public.teachers (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id),
  full_name text not null,
  branch text,
  email text,
  school_id uuid -- Index this
);

-- STUDENTS
create table public.students (
  id uuid primary key default uuid_generate_v4(),
  student_number text not null,
  full_name text not null,
  class_id uuid, -- Reference to classes
  school_id uuid
);

-- DUTY PLANS
create table public.duty_plans (
  id uuid primary key default uuid_generate_v4(),
  date date not null,
  area text not null,
  teacher_id uuid references public.teachers(id),
  school_id uuid,
  created_at timestamptz default now()
);

-- RLS EXAMPLES
alter table public.users enable row level security;

create policy "Users can view their own profile" on public.users
  for select using (auth.uid() = id);

create policy "Admins can view all profiles" on public.users
  for select using (
    exists (select 1 from public.users where id = auth.uid() and role_id = 'admin')
  );
```
