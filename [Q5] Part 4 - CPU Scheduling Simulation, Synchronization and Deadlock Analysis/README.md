## Task 1 - Scheduling simulator

### Tie-breaking / ordering rules (so the output is repeatable)

- **Same arrival time** -> order by the order they appear in the input list.
- **SJF, equal bursts** -> use arrival time first, then input order.
- **Round Robin** -> when a process is preempted at the end of its quantum, any processes that arrived during that quantum go into the ready queue before the preempted process goes to the back.
- Turnaround = completion − arrival; Waiting = turnaround − burst.

### Dataset (5 processes) and results (Round Robin quantum = 3)

Dataset: `P1(arr=0,burst=7), P2(arr=2,burst=4), P3(arr=4,burst=1), P4(arr=5,burst=4), P5(arr=6,burst=3)`

FCFS — average waiting **5.80**, average turnaround **9.60**.
SJF — average waiting **4.80**, average turnaround **8.60**.
Round Robin (q=3) — average waiting **8.80**, average turnaround **12.60**.

(The program prints the full per-process table for each one. SJF gives the best averages here because the short job P3 gets run early and out of the way. Round Robin has higher averages because of all the switching, but it shares the CPU more evenly, which is better for response time.)

---

## Task 2 - Priority scheduling with aging

**Convention (used everywhere here): a higher number means higher priority.**

### The starvation scenario

Picture CampusConnect's backend at a busy time. A low-priority **nightly report job `P_low`** arrives at t=0 with priority **1**. At the same time, short high-priority request handlers keep coming in: assume a **new priority-5 process arrives every 2 time units** for the whole window (at t=0, 2, 4, and so on). The scheduler always runs the highest priority available, so at every point there's a priority-5 handler ready and `P_low` keeps getting skipped. Because the high-priority arrivals never stop during the window, `P_low` waits forever. That's real starvation, not just a long wait - if the process set were fixed and no new jobs arrived, `P_low` would eventually run once the others finished, so the "new jobs keep arriving" part is what makes it genuine starvation.

### How aging fixes it

**Aging rule I chose: every 3 time units a process spends waiting, add 1 to its priority.** As `P_low` waits, its priority slowly goes up until it's higher than the incoming priority-5 handlers and finally gets to run.

| Time | `P_low` priority | Highest waiting competitor | `P_low` scheduled? | Note                                     |
|-----:|-----------------:|---------------------------:|:------------------:|------------------------------------------|
| 0    | 1                | 5                          | no                 | arrives; a priority-5 handler runs       |
| 3    | 2                | 5                          | no                 | waited 3 units -> +1 (1→2)               |
| 6    | 3                | 5                          | no                 | +1 (2→3)                                 |
| 9    | 4                | 5                          | no                 | +1 (3→4)                                 |
| 12   | 5                | 5                          | no                 | +1 (4→5); tied, so the earlier arrival still waits one step |
| 15   | 6                | 5                          | **yes**            | +1 (5→6); now higher than the arrivals -> runs |

The process that would have starved without aging is **`P_low`** (the nightly report job). With aging its priority climbs 1 → 2 → 3 → 4 → 5 → 6 over the trace, and once it passes 5 at t=15 the scheduler runs it, so no process waits forever.

---

## Task 3 - Synchronization fix (notes)

`sync_demo.py` runs two threads. Each one tries to add 1 to a shared counter `ITERATIONS = 100,000` times, so the correct total is 200,000.

**Before (race guaranteed).** A `threading.Barrier(2)` sits between the read and the write of each increment. Neither thread is allowed to write until both have read, so both always read the same old value and one of the two writes is always lost. The final count comes out to **100,000** (exactly half) and prints `WRONG` every single run - it's not a random once-in-a-while bug from a sleep, it happens every time.

**After (fixed).** The barrier is removed completely and the increment is wrapped in a **binary semaphore** (`acquire`/`release`, i.e. wait/signal), so only one thread does the read-modify-write at a time. The final count is **200,000** (`CORRECT`) every run. The barrier is not kept in the fixed version: if one thread got the lock and then waited at a 2-party barrier inside the locked section, the other thread could never reach the barrier (it can't get the lock), so they'd both get stuck - a deadlock. The barrier was only there to force the bug in the "before" version; once the semaphore is doing real mutual exclusion, it isn't needed and would be unsafe to keep.

---

## Task 4 - Deadlock analysis

### Scenario: 3 processes, 3 resources in the CampusConnect backend

Three resources, each with one instance: **R1 = a database connection**, **R2 = a file lock** (on an upload being written), **R3 = a cache lock** (on a Redis key). Three worker processes each hold one and want another:

- **P1** holds R1 (database connection) and wants R2 (file lock).
- **P2** holds R2 (file lock) and wants R3 (cache lock).
- **P3** holds R3 (cache lock) and wants R1 (database connection).

### The four conditions, one sentence each

- **Mutual exclusion** - each of R1, R2, R3 is a single-instance lock that only one process can hold at a time, so anyone else asking for it has to wait.
- **Hold-and-wait** - each process is holding one resource (P1 has R1, P2 has R2, P3 has R3) while waiting for another one it has asked for.
- **No preemption** - none of the locks can be taken away by force; a process only gives up a resource when it chooses to, after it's done.
- **Circular wait** - P1 waits for R2 (held by P2), P2 waits for R3 (held by P3), and P3 waits for R1 (held by P1), which forms a loop P1 → P2 → P3 → P1.

### Resource-allocation graph (directed edges, as text)

```
R1 -> P1   (allocated)
P1 -> R2   (requested)
R2 -> P2   (allocated)
P2 -> R3   (requested)
R3 -> P3   (allocated)
P3 -> R1   (requested)
```

### The one edge to remove

Remove **`P3 -> R1` (P3's request for the database connection)**. Without that request, P3 isn't waiting on R1 anymore, so the loop P1 → P2 → P3 → P1 is broken. P3 can finish and release R3, then P2 can get R3 and finish, then P1 can get R2 - the processes finish one after another and there's no deadlock.

### One prevention strategy and one limitation

**Strategy: impose resource ordering.** Give the resources a fixed order R1 < R2 < R3 and make every process ask for locks only in that increasing order. A circular wait then can't happen, because no process would be holding a higher-numbered lock while asking for a lower-numbered one - which is exactly what P3 does when it holds R3 and asks for R1.

**Limitation:** it needs you to know all the resources and agree on one global order ahead of time, and getting every part of the code to follow that order is hard. It can also force a process to grab a low-numbered resource earlier than it really needs it, just to keep the order right, which means it holds that resource longer than necessary and lets fewer things run at the same time.