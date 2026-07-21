-- Task 6: CampusConnect - transaction.sql : enroll student 109 into CS101 as one unit
BEGIN;

UPDATE courses
SET available_seats = available_seats - 1
WHERE course_code = 'CS101' AND available_seats > 0;

INSERT INTO
  enrollments (student_id, course_code, status)
VALUES
  (109, 'CS101', 'active');

COMMIT;