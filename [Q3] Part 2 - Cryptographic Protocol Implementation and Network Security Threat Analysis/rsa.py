# Task 1 - RSA key generation, encryption and decryption from first principles.

from math import gcd

def is_prime(x: int) -> bool:
  if x < 2:
    return False
  
  i = 2
  while i * i <= x:
    if x % i == 0:
      return False
    i += 1

  return True

def egcd(a: int, b: int) -> tuple[int, int, int]:
  if b == 0:
    return (a, 1, 0)
  
  g, x, y = egcd(b, a % b)
  return (g, y, x - (a // b) * y)

def mod_inverse(e: int, phi: int) -> int:
  g, x, _ = egcd(e, phi)

  if g != 1:
    raise ValueError(f"e={e} is not invertible mod phi={phi} (they are not coprime)")
  
  return x % phi

def choose_e(phi: int) -> int:
  e = 3
  while e < phi:
    if gcd(e, phi) == 1:
      return e
    e += 2
    
  raise ValueError("no valid e found (phi too small)")

def rsa_demo(p: int, q: int, m: int, e: int | None = None, label: str = "") -> None:
  print(f"===== RSA test case {label} =====")

  if not (is_prime(p) and is_prime(q)):
    raise ValueError(f"p={p} and q={q} must both be prime")
  if p == q:
    raise ValueError("p and q must be different (if p == q, n is easy to factor and RSA is broken)")

  n = p * q
  phi = (p - 1) * (q - 1)
  print(f"p = {p}, q = {q}")
  print(f"n = p*q = {n}")
  print(f"phi(n) = (p-1)(q-1) = {phi}")

  if not (0 <= m < n):
    raise ValueError(f"message m={m} must satisfy 0 <= m < n ({n})")

  if e is None:
    e = choose_e(phi)
  if not (1 < e < phi and gcd(e, phi) == 1):
    raise ValueError(f"e={e} must satisfy 1 < e < phi and gcd(e, phi) == 1")

  d = mod_inverse(e, phi)
  print(f"e = {e}   (public exponent, gcd(e, phi) = {gcd(e, phi)})")
  print(f"d = {d}   (private exponent, check: (d*e) mod phi = {(d * e) % phi})")

  c = pow(m, e, n)
  recovered = pow(c, d, n)
  print(f"message   m = {m}")
  print(f"cipher    c = m^e mod n = {c}")
  print(f"recovered m = c^d mod n = {recovered}")

  assert recovered == m, "RSA round-trip failed: recovered message != original"
  print("round-trip OK (recovered == original)\n")


if __name__ == "__main__":
  rsa_demo(p=3, q=11, m=4, e=3, label="(a) worked example")
  rsa_demo(p=17, q=23, m=112, e=None, label="(b) my example")