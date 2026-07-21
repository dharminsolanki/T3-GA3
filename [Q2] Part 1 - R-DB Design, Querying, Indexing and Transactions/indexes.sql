-- Task 5 : CampusConnect - indexes.sql

-- Single-column index
CREATE INDEX idx_courses_instructor_id ON courses (instructor_id);
CREATE INDEX idx_enrollments_course_code ON enrollments (course_code);

-- Composite index
CREATE INDEX idx_enrollments_course_grade ON enrollments (course_code, grade);