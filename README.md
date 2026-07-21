# GA3 - Systems Engineering: Data, Security, Architecture & Operating Systems

Graded Assignment 3, built around **CampusConnect** - a web platform where students browse courses, enroll,
submit assignments and message instructors. The brief has four separate Parts, each graded on its own, so each
folder below is complete by itself and meant to be submitted as its own link.

The Database-engine and language choices are: **PostgreSQL 16** for Part 1, **Python 3** for the code in Parts 2 and 4. Part 3 is design-only. 
There are no images or PDFs anywhere - every schema, graph and diagram the brief asks for is written out in markdown files.

| Part | Folder |
|-----:|--------|
| 1 | `[Q2] Part 1 - Relational Database Design, Querying, Indexing & Transactions` |
| 2 | `[Q3] Part 2 - Cryptographic Protocol Implementation & Network Security Threat Analysis` |
| 3 | `[Q4] Part 3 - Software Architecture, Low-Level Design & Cloud Deployment Strategy` |
| 4 | `[Q5] Part 4 - CPU Scheduling Simulation, Synchronization & Deadlock Analysis` |

---

## [Q2] Part 1 - Relational Database Design, Querying, Indexing & Transactions

**Database Engine: PostgreSQL 16.**

This part builds CampusConnect's database - students, courses, enrollments and instructors. It has the schema, the sample data, the queries the reporting team needs, the indexes I picked for those queries, and one transaction with a short write-up on isolation levels.

### Files:
1. `schema.sql` - the `CREATE TABLE` statements (Task 1).
2. `data.sql` - the sample data, 10+ rows per table (Task 3), plus a commented-out example of a bad insert.
3. `indexes.sql` - the `CREATE INDEX` statements (Task 5).
4. `queries.sql` - the Task 4 queries (one file, each query labelled).
5. `transaction.sql` - the Task 6 enrollment transaction.
6. `README.md` - Normalization write-up (Task 2).

---

## [Q3] Part 2 - Cryptographic Protocol Implementation & Network Security Threat Analysis

**Language: Python 3.**

### Files:
- `rsa.py` - RSA key generation, encryption and decryption (Task 1).
- `diffie_hellman.py` - Diffie-Hellman key exchange (Task 2).
- `README.md` - Security-principle mapping (Task 3), Threat-model write-up (Task 4).

Both `rsa.py` and `diffie_hellman.py` print every step and check the answer at
the end (RSA: the decrypted message equals the original; Diffie-Hellman: both sides get the same shared secret).

### Test cases and expected output

- **RSA (a)** `p=3, q=11, e=3, m=4` -> `n=33, phi=20, d=7, c=31, recovered m=4`.
- **RSA (b)** `p=17, q=23, m=112` -> `n=391, phi=352, e=3, d=235, c=65, recovered m=112`.
- **DH worked example** `p=29, alpha=2, a=5, b=12` -> `A=3, B=7, K=16` on both sides.
- **DH (mine)** `p=23, alpha=5, a=6, b=15` -> `A=8, B=19, K=2` on both sides.

---

## [Q4] Part 3 - Notifications Service Design Document

### Files:
- `design_document.md` - High-Level Design, Architectural Style Choice, Low-Level Design, Scalability Plan, Cloud Deployment Recommendation

This is a design document for CampusConnect's new **notifications service**, which alerts students when a new assignment is posted or their enrollment status changes. It's a design-only document.

---

# Part 4 - CPU Scheduling Simulation, Synchronization & Deadlock Analysis

**Language: Python 3.**

### Files:
- `scheduler.py` - FCFS, SJF (non-preemptive) and Round Robin on one dataset (Task 1).
- `sync_demo.py` - a counter that's broken on purpose, then fixed with a semaphore (Task 3).
- `README.md` - the priority/aging trace (Task 2) and the deadlock analysis (Task 4).