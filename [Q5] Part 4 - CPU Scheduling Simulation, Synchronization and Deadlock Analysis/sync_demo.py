# Task 3 - Synchronization

import threading

ITERATIONS = 100_000

def runUnsynchronized() -> int:
  counter = 0
  barrier = threading.Barrier(2)

  def worker():
    nonlocal counter
    
    for _ in range(ITERATIONS):
      value = counter
      barrier.wait()
      counter = value + 1

  t1 = threading.Thread(target=worker)
  t2 = threading.Thread(target=worker)
  t1.start(); t2.start()
  t1.join(); t2.join()

  return counter


def runSynchronized() -> int:
  counter = 0
  sem = threading.Semaphore(1)

  def worker():
    nonlocal counter

    for _ in range(ITERATIONS):
      sem.acquire()
      counter += 1
      sem.release()

  t1 = threading.Thread(target=worker)
  t2 = threading.Thread(target=worker)
  t1.start(); t2.start()
  t1.join(); t2.join()

  return counter

if __name__ == "__main__":
  expected = 2 * ITERATIONS

  bad = runUnsynchronized()
  print(f"[BEFORE - no lock, Barrier forces the race]")
  print(f"  expected = {expected}, actual = {bad}  -> {'WRONG' if bad != expected else 'ok'}")
  print(f"  every iteration both threads read the same stale value, so one write is always lost.\n")

  good = runSynchronized()
  print(f"[AFTER - binary semaphore, no Barrier]")
  print(f"  expected = {expected}, actual = {good}  -> {'CORRECT' if good == expected else 'WRONG'}")