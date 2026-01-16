-- OKUL ASISTAN - GÜNCELLENMİŞ RLS POLİTİKALARI
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın

-- 1. Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Enable read/write for authenticated users" ON teachers;
DROP POLICY IF EXISTS "Enable read/write for authenticated users" ON duties;
DROP POLICY IF EXISTS "Enable read/write for authenticated users" ON students;
DROP POLICY IF EXISTS "Enable read/write for authenticated users" ON exam_halls;
DROP POLICY IF EXISTS "Enable read/write for authenticated users" ON notifications;

-- 2. Geliştirme için tüm kullanıcılara izin ver (anon dahil)
-- DİKKAT: Bu sadece geliştirme/test için! Production'da authenticated olmalı.

-- Teachers tablosu
CREATE POLICY "Enable all access for development" ON teachers
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Duties tablosu
CREATE POLICY "Enable all access for development" ON duties
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Students tablosu
CREATE POLICY "Enable all access for development" ON students
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Exam Halls tablosu
CREATE POLICY "Enable all access for development" ON exam_halls
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- Notifications tablosu
CREATE POLICY "Enable all access for development" ON notifications
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- =============================================
-- PRODUCTION İÇİN GÜVENLİ POLİTİKALAR
-- Aşağıdaki politikaları production'a geçerken kullanın
-- =============================================
/*
-- Teachers için güvenli politika
CREATE POLICY "Allow authenticated users to manage teachers" ON teachers
    FOR ALL 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Diğer tablolar için benzer şekilde...
*/
