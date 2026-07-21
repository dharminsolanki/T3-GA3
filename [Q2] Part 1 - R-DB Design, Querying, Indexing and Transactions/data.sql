-- Task 3: sample data - CampusConnect - data.sql : at least 10 rows per table.


-- Instructors
INSERT INTO
  instructors (instructor_id, full_name, email, department)
VALUES
  (1, 'Dr. Aparna Rao', 'aparna.rao@campusconnect.edu', 'Computer Science'),
  (2, 'Dr. Malcolm Reed', 'malcolm.reed@campusconnect.edu', 'Computer Science'),
  (3, 'Dr. Wei Zhang', 'wei.zhang@campusconnect.edu', 'Computer Science'),
  (4, 'Dr. Nadia Khan', 'nadia.khan@campusconnect.edu', 'Mathematics'),
  (5, 'Dr. Chidi Okafor', 'chidi.okafor@campusconnect.edu', 'Mathematics'),
  (6, 'Dr. Leon Alvarez', 'leon.alvarez@campusconnect.edu', 'Physics'),
  (7, 'Dr. Priya Nair', 'priya.nair@campusconnect.edu', 'Physics'),
  (8, 'Dr. Tomas Weber', 'tomas.weber@campusconnect.edu', 'Statistics'),
  (9, 'Dr. Grace Lin', 'grace.lin@campusconnect.edu', 'Statistics'),
  (10, 'Dr. Ivan Petrov', 'ivan.petrov@campusconnect.edu', 'Data Science');


-- Students
INSERT INTO
  students (student_id, full_name, email, signup_date)
VALUES
  (101, 'Ishita Bose', 'ishita.bose@student.edu', '2025-08-01'),
  (102, 'Marcus Bello', 'marcus.bello@student.edu', '2025-08-02'),
  (103, 'Sara Kim', 'sara.kim@student.edu', '2025-08-02'),
  (104, 'Diego Torres', 'diego.torres@student.edu', '2025-08-05'),
  (105, 'Mei Chen', 'mei.chen@student.edu', '2025-08-06'),
  (106, 'Omar Haddad', 'omar.haddad@student.edu', '2025-08-09'),
  (107, 'Lena Fischer', 'lena.fischer@student.edu', '2025-08-10'),
  (108, 'Ravi Menon', 'ravi.menon@student.edu', '2025-08-11'),
  (109, 'Yuki Tanaka', 'yuki.tanaka@student.edu', '2025-08-12'),
  (110, 'Ade Balogun', 'ade.balogun@student.edu', '2025-08-15');


-- Courses
INSERT INTO
  courses (course_code, title, instructor_id, capacity, available_seats)
VALUES
  ('CS101', 'Introduction to Programming', 1, 3, 1),
  ('CS202', 'Data Structures', 2, 40, 12),
  ('CS303', 'Database Systems', 3, 35, 5),
  ('CS404', 'Distributed Systems', 3, 30, 0), -- full: available_seats = 0
  ('MA101', 'Calculus I', 4, 50, 20),
  ('MA210', 'Linear Algebra', 4, 45, 9),
  ('PH150', 'Classical Mechanics', 6, 40, 15),
  ('PH260', 'Quantum Physics', 7, 25, 3),
  ('ST200', 'Probability', 8, 60, 30),
  ('DS300', 'Machine Learning', NULL, 30, 7); -- instructor not assigned yet


-- Enrollments (12 rows). One row per (student, course); grade NULL = not graded yet.
INSERT INTO
  enrollments (student_id, course_code, enrolled_on, status, grade)
VALUES
  (101, 'CS101', '2025-08-20', 'completed', 88.00),
  (101, 'CS202', '2025-08-21', 'active', NULL),
  (102, 'CS101', '2025-08-20', 'completed', 72.50),
  (102, 'CS303', '2025-08-22', 'active', NULL),
  (103, 'CS101', '2025-08-20', 'completed', 91.00),
  (103, 'MA101', '2025-08-23', 'completed', 64.00),
  (104, 'CS202', '2025-08-24', 'active', NULL),
  (104, 'PH150', '2025-08-25', 'completed', 55.00),
  (105, 'CS303', '2025-08-26', 'completed', 91.00),
  (106, 'MA210', '2025-08-27', 'completed', 78.00),
  (107, 'ST200', '2025-08-28', 'active', NULL),
  (108, 'PH260', '2025-08-29', 'completed', 83.50);


-- Legacy flat table rows
INSERT INTO
  enrollment_records (student_id, student_name, course_code, course_title, instructor_name, instructor_email)
VALUES
  (101, 'Ishita Bose', 'CS101', 'Introduction to Programming', 'Dr. Aparna Rao', 'aparna.rao@campusconnect.edu'),
  (101, 'Ishita Bose', 'CS202', 'Data Structures', 'Dr. Malcolm Reed', 'malcolm.reed@campusconnect.edu'),
  (102, 'Marcus Bello', 'CS101', 'Introduction to Programming', 'Dr. Aparna Rao', 'aparna.rao@campusconnect.edu'),
  (199, 'Ghost Student', 'CS101', 'Introduction to Programming', 'Dr. Aparna Rao', 'aparna.rao@campusconnect.edu');


-- ---------------------------------------------------------------------------
-- Insertion-order / referential-integrity demonstration (INTENTIONALLY COMMENTED OUT).

-- Each statement below WOULD raise a foreign-key error if run, because the referenced parent
-- row does not exist. They are commented so this script still runs top-to-bottom without errors,
-- exactly as the acceptance criteria require. Uncomment any one to see the violation.


--   -- (child: courses) instructor_id 999 has no parent row in instructors:
--   INSERT INTO courses (course_code, title, instructor_id, capacity, available_seats)
--       VALUES ('XX999', 'Orphan Course', 999, 10, 10);
--
--   -- (child: enrollments) student_id 777 has no parent row in students:
--   INSERT INTO enrollments (student_id, course_code) VALUES (777, 'CS101');
--
--   -- (child: enrollments) course_code 'ZZ000' has no parent row in courses:
--   INSERT INTO enrollments (student_id, course_code) VALUES (101, 'ZZ000');
-- ---------------------------------------------------------------------------