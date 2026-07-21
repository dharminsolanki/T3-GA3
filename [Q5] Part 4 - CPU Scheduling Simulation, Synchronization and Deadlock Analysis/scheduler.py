#Task 1 - CPU scheduling simulator: FCFS, SJF (non-preemptive), Round Robin

from dataclasses import dataclass

@dataclass
class Process:
  pid: str
  arrival: int
  burst: int
  order: int

def makeDataset() -> list[Process]:
  raw = [
    ("P1", 0, 7),
    ("P2", 2, 4),
    ("P3", 4, 1),
    ("P4", 5, 4),
    ("P5", 6, 3),
  ]
  return [Process(pid, a, b, i) for i, (pid, a, b) in enumerate(raw)]

def summarise(procs: list[Process], completion: dict[str, int]) -> dict:
  rows, totWt, totTat = [], 0, 0
  for p in procs:
    tat = completion[p.pid] - p.arrival
    wt = tat - p.burst
    totWt += wt
    totTat += tat
    rows.append((p.pid, p.arrival, p.burst, completion[p.pid], wt, tat))
  
  n = len(procs)
  return {"rows": rows, "avgWt": totWt / n, "avgTat": totTat / n}

def printResult(name: str, result: dict) -> None:
  print(f"----- {name} -----")
  print(f"{'PID':<5}{'Arrival':<9}{'Burst':<7}{'Complete':<10}{'Waiting':<9}{'Turnaround':<11}")

  for pid, arr, bur, comp, wt, tat in result["rows"]:
    print(f"{pid:<5}{arr:<9}{bur:<7}{comp:<10}{wt:<9}{tat:<11}")
  
  print(f"Average waiting time    = {result['avgWt']:.2f}")
  print(f"Average turnaround time = {result['avgTat']:.2f}\n")

def fcfs(procs: list[Process]) -> dict:
  ordered = sorted(procs, key=lambda p: (p.arrival, p.order))
  time, completion = 0, {}

  for p in ordered:
    time = max(time, p.arrival) + p.burst
    completion[p.pid] = time
  
  return summarise(procs, completion)

def sjf(procs: list[Process]) -> dict:
  remaining = list(procs)
  time, completion = 0, {}

  while remaining:
    available = [p for p in remaining if p.arrival <= time]

    if not available:
      time = min(p.arrival for p in remaining)
      continue

    chosen = min(available, key=lambda p: (p.burst, p.arrival, p.order))
    time += chosen.burst
    completion[chosen.pid] = time
    remaining.remove(chosen)

  return summarise(procs, completion)


def roundRobin(procs: list[Process], quantum: int) -> dict:
  byArrival = sorted(procs, key=lambda p: (p.arrival, p.order))
  remaining = {p.pid: p.burst for p in procs}
  completion, ready, time, idx = {}, [], 0, 0

  def releaseUpTo(t: int):
    nonlocal idx
    while idx < len(byArrival) and byArrival[idx].arrival <= t:
      ready.append(byArrival[idx])
      idx += 1

  releaseUpTo(time)

  while ready or idx < len(byArrival):
    if not ready:
      time = byArrival[idx].arrival
      releaseUpTo(time)

    current = ready.pop(0)
    run = min(quantum, remaining[current.pid])
    time += run
    remaining[current.pid] -= run

    releaseUpTo(time)

    if remaining[current.pid] > 0:
      ready.append(current)
    else:
      completion[current.pid] = time

  return summarise(procs, completion)


if __name__ == "__main__":
  QUANTUM = 3
  data = makeDataset()
  
  print("Dataset: " + ", ".join(f"{p.pid}(arr={p.arrival}, burst={p.burst})" for p in data))
  print(f"Round Robin time quantum = {QUANTUM}\n")

  printResult("FCFS", fcfs(data))
  printResult("SJF (non-preemptive)", sjf(data))
  printResult(f"Round Robin (q={QUANTUM})", roundRobin(data, QUANTUM))