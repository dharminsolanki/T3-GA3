## Task 2 : Section 1 - Normalization write-up

### What the un-normalized version looked like

Before splitting anything up, CampusConnect kept one flat row per enrollment. That's the shape of the `enrollment_records` table (I left it in the schema so the set-operation query in Task 4 has something to compare against). A few rows of it:

| student_id | student_name | course_code | course_title    | instructor_name | instructor_email               |
|-----------:|--------------|-------------|-----------------|-----------------|--------------------------------|
| 101        | Ishita Bose  | CS101       | Intro to Prog.  | Dr. Aparna Rao  | aparna.rao@campusconnect.edu   |
| 101        | Ishita Bose  | CS202       | Data Structures | Dr. Malcolm Reed| malcolm.reed@campusconnect.edu |
| 102        | Marcus Bello | CS101       | Intro to Prog.  | Dr. Aparna Rao  | aparna.rao@campusconnect.edu   |

Notice the course title and the instructor's name and email get repeated on every row for the same course. That repetition is the problem normalization fixes.

### 1NF - no repeating groups

The flat table is already atomic - no cell holds a list like "CS101, CS202". To have a proper key I need the pair `(student_id, course_code)`, because one student takes many courses and one course has many students, so neither column alone can identify a row. So 1NF is met: atomic columns, a defined primary key, no repeating groups.

### 2NF - no partial dependency on part of the key

2NF means no non-key column should depend on only part of the composite key. The flat table breaks this twice:

- `student_id -> student_name`. A student's name has nothing to do with which course the row is about, so it depends on only half the key. Fixed by moving the name into `students`, keyed on `student_id` on its own.
- `course_code -> course_title, instructor_id`. A course's title and who teaches it depend on the course, not on the student. Fixed by moving those into `courses`, keyed on `course_code` on its own.

After that, the only columns left in `enrollments` are `grade`, `status` and `enrolled_on`, and each of those really does depend on the whole key (this student, in this course). So 2NF is met.

### 3NF - no non-key column depending on another non-key column

3NF means a non-key column shouldn't depend on another non-key column. The one left is:

- `instructor_id -> full_name, email, department`. If the `courses` table still held the instructor's details, those columns would depend on `instructor_id`, which is itself not the key (the key is `course_code`). So you get a chain: `course_code -> instructor_id -> instructor_email`. Fixed by putting the instructor's details in their own `instructors` table and leaving just the `instructor_id` foreign key in `courses`.

Final result: four tables - `instructors`, `students`, `courses`, `enrollments` - where every non-key column depends on the key, the whole key, and nothing but the key. This gets rid of the three usual problems: the instructor's email is stored once instead of on every row (update problem), a course doesn't disappear when its last student drops it (delete problem), and a course can be added before any student enrolls (insert problem).

---

## Section 2 - Indexing justification (Task 5)

The indexes are in `indexes.sql`. Each one is chosen for a specific query in `queries.sql`:

- **`idx_courses_instructor_id` on `courses(instructor_id)`** - the INNER JOIN, the RIGHT JOIN and the `EXISTS` query all match `courses.instructor_id` to `instructors.instructor_id`. Without the index Postgres has to scan the whole `courses` table for the join; with it, it can look the matching rows up directly.
- **`idx_enrollments_course_code` on `enrollments(course_code)`** - the `IN ('CS101','CS202','CS303')` query and the LEFT JOIN both filter or join `enrollments` by `course_code`. `course_code` is the second column of the composite primary key, so the primary key alone doesn't give a fast lookup on it by itself. This index does.
- **`idx_enrollments_course_grade` on `enrollments(course_code, grade)`** (composite) - the window-function query groups by `course_code` and orders by `grade` descending. Having both columns in one index, in that order, lets the query use the index for the grouping and the sorting instead of sorting separately. The order matters: `course_code` first because that's the grouping column, `grade` second because that's the sort column.

**A column I chose not to index: `enrollments.status`.** Queries do filter on it, but it only has three possible values - `active`, `dropped`, `completed` - across the whole table. That's very low variety, so any one value still matches a big chunk of rows, and Postgres would usually just scan the table anyway instead of using the index. Meanwhile I'd still pay to update the index on every insert and update. Since `enrollments` gets written to a lot (every enroll and drop), an index that mostly doesn't get used is just extra cost for no real gain.

---

## Section 3 - Transaction & isolation-level analysis (Task 6)

`transaction.sql` puts two related writes in one `BEGIN ... COMMIT`: lower `courses.available_seats` by one and insert the matching row into `enrollments`. Both happen together, or neither does - if the insert failed for some reason, the `ROLLBACK` puts the seat back, so you never end up with a seat taken but no enrollment, or an enrollment with no seat taken.

### The concurrent-access scenario

CS101 has **one** seat left (`available_seats = 1`). Two students, 108 and 109, both try to enroll at the exact same moment. With a weak isolation level this becomes a **lost update**:

1. Transaction A reads `available_seats = 1`.
2. Transaction B also reads `available_seats = 1` (before A has committed).
3. Both think there's a seat, both work out `1 - 1 = 0`, both write `0` and insert their enrollment.
4. Now there are two enrollments but the seat count only went down by one. The course is over capacity, and one of the two updates was lost.

(A related problem, a **dirty read**, would be Transaction B reading A's new seat count before A commits, and then A rolls back - so B acted on a value that never really existed.)

### Which isolation level fixes it, and why

- **Read Uncommitted** - allows dirty reads. Not good enough.
- **Read Committed** (the Postgres default) - stops dirty reads, but not this lost update: both transactions read a committed `1` before either one writes, so both still go ahead.
- **Repeatable Read** - in Postgres this uses a snapshot. It would actually catch this case by cancelling the second transaction with a serialization error when it notices they both changed the same row - which works if the app retries. On the strict standard definition, though, Repeatable Read isn't guaranteed to stop this kind of problem.
- **Serializable** - guarantees the result is the same as if the two enrollments had run one after the other. So the second transaction either sees the first one's committed change (and correctly finds `0` seats) or gets cancelled and retried.

**My choice: Serializable for the enrollment transaction.** It's the level that makes the "last seat" guarantee hold no matter how the two transactions overlap. In a real system I'd also accept Read Committed plus an explicit `SELECT ... FOR UPDATE` lock on the course row, which locks the seat count for that transaction and gives the same safety at a lower cost than serializing everything.