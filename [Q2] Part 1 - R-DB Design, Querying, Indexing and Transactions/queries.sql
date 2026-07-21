-- Task 4 : CampusConnect - queries.sql
-- Every query is preceded by a one-line comment (what it answers) and tagged with the Task 4 sub-requirement it satisfies.

-- IN: which students are enrolled in any of the three core CS courses?
SELECT DISTINCT s.full_name, e.course_code
FROM students s
JOIN enrollments e ON e.student_id = s.student_id
WHERE e.course_code IN ('CS101', 'CS202', 'CS303')
ORDER BY s.full_name;

-- BETWEEN: which completed enrollments earned a "merit" grade in the 70-89 band?
SELECT student_id, course_code, grade
FROM enrollments
WHERE grade BETWEEN 70 AND 89
ORDER BY grade DESC;

-- IS NULL: which active enrollments have not been graded yet? (correct null test, not = NULL)
SELECT student_id, course_code, status
FROM enrollments
WHERE grade IS NULL
ORDER BY student_id;

-- GROUP BY + HAVING: which courses have more than one enrollment? (HAVING filters the aggregate, not WHERE)
SELECT course_code, COUNT(*) AS enrollment_count
FROM enrollments
GROUP BY course_code
HAVING COUNT(*) > 1
ORDER BY enrollment_count DESC;

-- JOIN #1 - INNER JOIN: course title + instructor for every course that HAS an instructor assigned.
SELECT c.course_code, c.title, i.full_name AS instructor
FROM courses c
INNER JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER BY c.course_code;

-- JOIN #2 - LEFT JOIN: every student and their enrollments; students with none still appear (Ade Balogun -> NULLs).
SELECT s.full_name, e.course_code, e.status
FROM students s
LEFT JOIN enrollments e ON e.student_id = s.student_id
ORDER BY s.full_name, e.course_code;

-- JOIN #3 - RIGHT JOIN: every instructor and the courses they teach; instructors teaching nothing still appear (Dr. Okafor -> NULLs).
SELECT c.course_code, i.full_name AS instructor
FROM courses c
RIGHT JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER BY i.full_name;

-- JOIN #4 - FULL OUTER JOIN: unmatched on BOTH sides at once - courses with no instructor (DS300) and instructors with no course (Dr. Okafor).
-- NOTE: PostgreSQL supports FULL OUTER JOIN natively. On MySQL, substitute:  <left join> UNION <right join>.
SELECT c.course_code, i.full_name AS instructor
FROM courses c
FULL OUTER JOIN instructors i ON i.instructor_id = c.instructor_id
WHERE c.course_code IS NULL OR i.instructor_id IS NULL
ORDER BY i.full_name;

-- scalar subquery: list courses whose available_seats is below the average across all courses.
SELECT course_code, available_seats
FROM courses
WHERE available_seats < (SELECT AVG(available_seats) FROM courses) -- subquery returns a single scalar
ORDER BY available_seats;

-- correlated subquery: each student with their personal best grade (subquery re-runs per outer row).
SELECT s.full_name, (SELECT MAX(e.grade) FROM enrollments e WHERE e.student_id = s.student_id) AS best_grade -- correlated on s.student_id
FROM students s
ORDER BY best_grade DESC NULLS LAST;

-- EXISTS: which instructors are actually teaching at least one course right now?
SELECT i.full_name
FROM instructors i
WHERE EXISTS (SELECT 1 FROM courses c WHERE c.instructor_id = i.instructor_id)
ORDER BY i.full_name;

-- set operation - EXCEPT: (student_id, course_code) pairs in the legacy flat table that are NOT in the clean enrollments table.
-- Surfaces the orphan "Ghost Student" (199) that normalisation would have rejected.
SELECT student_id, course_code
FROM enrollment_records
EXCEPT
SELECT student_id, course_code
FROM enrollments;

-- NOTE: EXCEPT works on PostgreSQL. MySQL <8.0.31 lacks EXCEPT - substitute a LEFT JOIN ... WHERE ... IS NULL anti-join.
-- window function - RANK with PARTITION BY: rank students by grade WITHIN each course; ties share a rank.
SELECT course_code, student_id, grade, RANK() OVER (PARTITION BY course_code ORDER BY grade DESC) AS rank_in_course
FROM enrollments
WHERE grade IS NOT NULL
ORDER BY course_code, rank_in_course;