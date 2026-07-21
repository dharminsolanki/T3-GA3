# Task 2 - Diffie-Hellman key exchange from first principles.

def is_prime(x: int) -> bool:
  if x < 2:
    return False
  
  i = 2
  while i * i <= x:
    if x % i == 0:
      return False
    i += 1

  return True

def is_primitive_root(alpha: int, p: int) -> bool:
  seen = set()
  val = 1
  for _ in range(1, p):
    val = (val * alpha) % p
    seen.add(val)
  return len(seen) == p - 1

def dh_demo(p: int, alpha: int, a: int, b: int, label: str = "") -> None:
  print(f"===== Diffie-Hellman test case {label} =====")

  if not is_prime(p):
    raise ValueError(f"p={p} must be prime")
  if not is_primitive_root(alpha, p):
    raise ValueError(f"alpha={alpha} is not a primitive root modulo {p}")
  if not (1 < a < p - 1):
    raise ValueError(f"Alice's private key a={a} must satisfy 1 < a < p-1")
  if not (1 < b < p - 1):
    raise ValueError(f"Bob's private key b={b} must satisfy 1 < b < p-1")
  
  print(f"public: p = {p}, alpha = {alpha}   (alpha is a primitive root mod p)")
  print(f"private: a = {a} (Alice), b = {b} (Bob)")

  A = pow(alpha, a, p)
  B = pow(alpha, b, p)
  print(f"A = alpha^a mod p = {A}   (Alice -> Bob)")
  print(f"B = alpha^b mod p = {B}   (Bob -> Alice)")

  K_alice = pow(B, a, p)   # K = B^a mod p
  K_bob = pow(A, b, p)     # K = A^b mod p
  print(f"Alice's K = B^a mod p = {K_alice}")
  print(f"Bob's   K = A^b mod p = {K_bob}")

  assert K_alice == K_bob, "shared secrets do not match!"

  print(f"MATCH: both sides agree on shared secret K = {K_alice}\n")


if __name__ == "__main__":
  dh_demo(p=29, alpha=2, a=5, b=12, label="(worked example)")
  dh_demo(p=23, alpha=5, a=6, b=15, label="(my example)")