-- Task 1: CampusConnect - schema.sql : Schema design (PKs, one FK relationship, domain constraints, 3NF)

-- Instructors
DROP TABLE IF EXISTS instructors;
CREATE TABLE instructors (
  instructor_id INT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  department VARCHAR(80) NOT NULL
);

-- Students
DROP TABLE IF EXISTS students;
CREATE TABLE students (
  student_id INT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  signup_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Courses
DROP TABLE IF EXISTS courses;
CREATE TABLE courses (
  course_code VARCHAR(10) PRIMARY KEY,
  title VARCHAR(120) NOT NULL,
  instructor_id INT,
  capacity INT NOT NULL CHECK (capacity > 0),
  available_seats INT NOT NULL CHECK (available_seats >= 0),
  CONSTRAINT fk_course_instructor FOREIGN KEY (instructor_id) REFERENCES instructors (instructor_id)
);

-- Enrollments
DROP TABLE IF EXISTS enrollments;
CREATE TABLE enrollments (
  student_id INT NOT NULL,
  course_code VARCHAR(10) NOT NULL,
  enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
  status VARCHAR(10) NOT NULL DEFAULT 'active'
  CHECK (status IN ('active', 'dropped', 'completed')),
  grade NUMERIC(5, 2) CHECK (
    grade >= 0
    AND grade <= 100
  ),
  PRIMARY KEY (student_id, course_code),
  CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students (student_id),
  CONSTRAINT fk_enroll_course FOREIGN KEY (course_code) REFERENCES courses (course_code)
);

-- Enrollment records
DROP TABLE IF EXISTS enrollment_records;
CREATE TABLE enrollment_records (
  student_id INT, 
  student_name VARCHAR(100), 
  course_code VARCHAR(10), 
  course_title VARCHAR(120), 
  instructor_name VARCHAR(100), 
  instructor_email VARCHAR(150));