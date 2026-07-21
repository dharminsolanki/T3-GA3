## Task 3 - Security-principle mapping

**RSA** covers **confidentiality**, and it can also give **authentication** and **non-repudiation**. If you encrypt with the other person's public key, only their private key can decrypt it, so the message stays private (confidentiality). If instead the owner signs a message with their own private key, anyone can check it with the matching public key, which proves it came from that person (authentication) and means they can't later say they didn't send it (non-repudiation). My `rsa.py` shows the confidentiality use.

**Diffie-Hellman** covers **confidentiality** only. It lets two people agree on a shared secret over an open line, and they then use that secret with a normal cipher to keep their messages private. On its own it gives **no authentication**: nothing ties a value to a person, so plain Diffie-Hellman can be attacked by a man-in-the-middle who swaps in their own numbers. That's why real systems also sign or certify the exchange.

**Why Diffie-Hellman is a key-exchange protocol and not an encryption algorithm.** Diffie-Hellman never takes a message and never produces ciphertext. All it does is let both sides work out the same number `K` from their public and private values. There is no encrypt or decrypt step in it - you take that `K` and feed it into a separate cipher like AES to actually protect data. RSA is different: the same key-pair maths both makes the keys and directly turns a message into ciphertext (`c = m^e mod n`) and back (`m = c^d mod n`), so RSA can do key generation and encryption/decryption itself, while Diffie-Hellman only does the agreement step.

---

## Task 4 - Threat-model write-up

Right now CampusConnect's login page runs on plain HTTP with no intrusion monitoring. Here's what I'd put in place.

### (a) Firewall placement, type, and a concrete rule

Put a **network firewall at the perimeter**, between the public internet and CampusConnect's application servers, so all incoming traffic goes through it before reaching them. The database server sits behind it in a private subnet with no direct route from the internet. For this case I'd use a **hardware firewall** (or the cloud equivalent, a managed network firewall / security group) at the network edge, because it protects every server at once and doesn't run on an app server where an attacker who breaks in could switch it off. One concrete rule: **block all incoming traffic to the database port (TCP 5432) except from the application servers' IP range** - the public should never reach Postgres directly, only the app tier should.

### (b) Host-based IDS, Network-based IDS, or both

**Both.** A **Network-based IDS** watches the network traffic, so it can spot things like a port scan or a flood of login attempts hitting the perimeter - but it can't see inside encrypted (TLS) traffic and can't tell what happened on a server after the traffic arrived. A **Host-based IDS** runs on the servers themselves and can catch what the network sensor misses - a changed system file, a strange process, or a login from an unexpected account - but only on the machine it's installed on. Running both covers both sides: the network one for traffic in transit, the host one for what actually lands on a server.

### (c) HTTP vs HTTPS for the login page

**HTTPS.** Over plain HTTP the username and password are sent as plain text, so anyone on the same network (campus Wi-Fi, a hacked router) can read them straight off the wire - this is **credential sniffing**. HTTPS encrypts the connection with TLS, so the login details can't be read by someone listening in, and it also protects the session cookie afterwards, which helps stop the **session hijacking** that a stolen token would allow.

### (d) Authentication design (least privilege + MFA)

Use **multi-factor authentication** with two factors of different types:

1. **Something you know** - the account password (stored hashed with a slow algorithm like bcrypt).
2. **Something you have** - a time-based one-time code (TOTP) from an authenticator app on the user's phone.

Because the two factors are different types of thing, stealing or guessing the password alone isn't enough - the attacker would also need the phone, and the code changes every 30 seconds.

Using **least privilege**, each role only gets the permissions it actually needs:

- **Student** - can see their own enrollments, grades and notifications, and enroll in or drop their own courses. No access to other students' records and no editing of course or grade data.
- **Instructor** - can see the class list and submit grades for their own courses only. Can't create accounts or touch courses they don't teach.
- **Admin** - can manage accounts, courses and settings. Admins should have MFA on every login, and ideally use a separate account from their normal student or teaching account, so a hacked everyday session can't be used to get admin powers.

### (e) One plausible attack, classified

**Attack (passive): credential sniffing on shared Wi-Fi.** An attacker joins the same campus Wi-Fi as a student and quietly records the HTTP traffic going to CampusConnect's login page. Because the page is plain HTTP, the student's username and password show up as plain text in that recorded traffic, and the attacker just reads them out later.

**Classification: passive.** The attacker only watches and copies the traffic - they don't change, add, delay or block anything, and the student's session looks completely normal. That's what makes it a passive attack (it goes after confidentiality and is hard to notice because nothing looks disturbed). It would only turn into an active attack later, if the attacker used the stolen login to sign in and change data.