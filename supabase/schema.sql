-- OKUL ASISTAN SQL SCHEMA

-- 1. Enable UUID Extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TEACHERS TABLE
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id TEXT NOT NULL, -- Logical grouping for multi-tenancy
    name TEXT NOT NULL,
    branch TEXT,
    available_days JSONB DEFAULT '[]'::jsonb, -- e.g. [1, 2, 3]
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Teachers
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read/write for authenticated users" ON teachers
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');


-- 3. DUTIES TABLE
CREATE TABLE IF NOT EXISTS duties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id TEXT NOT NULL,
    date DATE NOT NULL,
    area TEXT NOT NULL,
    teacher_id UUID REFERENCES teachers(id),
    teacher_name TEXT, -- Denormalized for easier reporting
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Duties
ALTER TABLE duties ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read/write for authenticated users" ON duties
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');


-- 4. BUTTERFLY SYSTEM: STUDENTS
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id TEXT NOT NULL,
    number TEXT NOT NULL,
    name TEXT NOT NULL,
    class_name TEXT NOT NULL, -- e.g. '9-A'
    branch TEXT, -- e.g. 'A'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Students
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read/write for authenticated users" ON students
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');


-- 5. BUTTERFLY SYSTEM: EXAM HALLS
CREATE TABLE IF NOT EXISTS exam_halls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id TEXT NOT NULL,
    name TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 20,
    column_count INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Exam Halls
ALTER TABLE exam_halls ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read/write for authenticated users" ON exam_halls
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');


-- 6. NOTIFICATIONS TABLE (For Edge Function Trigger)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_user_id UUID, -- Specific user (matches auth.users.id)
    target_segment TEXT, -- e.g. 'Teachers'
    target_tags JSONB, -- For advanced scheduling e.g. {"school_id": "123"}
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, sent, failed
    send_at TIMESTAMP WITH TIME ZONE, -- Scheduled time
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for Notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable read/write for authenticated users" ON notifications
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- 7. NOTIFICATION TRIGGER (Concepts)
-- You would typically create a Database Webhook in the Supabase Dashboard
-- pointing to the 'send-notification' Edge Function on INSERT into 'notifications' table.

