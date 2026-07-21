## Section 1 - High-Level Design

### Modules / components

1. **Event Ingestion module** - the entry point. Other parts of CampusConnect (the assignment service, the enrollment workflow) send it events like `AssignmentPosted` or `EnrollmentStatusChanged`.
2. **Notification-Generation module** - turns a raw event into one or more notifications, one per recipient. For example, an `AssignmentPosted` for a course becomes one notification for each enrolled student.
3. **User-Preferences module** - decides whether and how each student wants to be notified (in-app only, email, push; all at once or in a daily digest; quiet hours).
4. **Delivery module** - actually sends each notification on the chosen channel and retries if it fails.
5. **Database / storage** - keeps the notifications, their status (queued / sent / read), and each user's preference settings.

### The four layers and what each one does

- **Presentation layer** - the API and UI part. It has the endpoint other services call to raise an event, and the endpoint the student's app uses to load their notifications and change their settings. It only takes requests and formats responses; it has no business rules.
- **Business layer** - the actual logic: turning one event into many notifications, applying the user's preferences, choosing the channel, deciding immediate vs digest, and scheduling retries after a failure.
- **Data-access layer** - the part that reads and writes notifications and preferences. It hides the SQL and the database connections behind simple method calls, so the business layer never touches the database directly.
- **Database layer** - the actual database (the tables for notifications and preferences, plus any queue used to hold delivery work).

### How one notification event flows through the layers

1. The assignment service posts a new assignment and calls CampusConnect's notification API. This hits the **presentation layer**, which checks the request and passes an `AssignmentPosted` event inward.
2. The **business layer** looks up who's enrolled in the course, and for each student asks the preferences logic how they want to be notified. It creates one notification per student and channel.
3. Each notification is saved through the **data-access layer** into the **database layer** with status `queued`.
4. The **business layer** then picks up the queued notifications and sends each one on its channel. On success it updates the row to `sent`; on failure it schedules a retry - again through the data-access layer.
5. When the student opens their app, the **presentation layer** loads their notifications (through the data-access layer) and marks the ones they open as `read`.

---

## Section 2 - Architectural Style Choice

**My choice: event-driven architecture.**

Notifications are always a reaction to something happening somewhere else (an assignment is posted, an enrollment changes), so treating them as events on a message queue fits the problem much better than making every other part of the system call the notification code and wait for it.

**Three concrete advantages for this feature:**

1. **It's separated from the core system.** The assignment and enrollment services just publish an event and move on. They don't wait for notifications to be created or sent, and they keep working even if the notification service is down for a bit. That keeps the important enroll and submit actions fast.
2. **It handles busy periods well.** During a spike - an instructor posting an assignment to a 500-student course, or lots of enrollment changes on results day - the events sit in the queue and the notification workers process them as fast as they can, instead of the spike hitting the core system directly.
3. **It's easy to extend.** One event can be handled by several workers at once (in-app, email, push), and adding a new channel just means adding a new worker without changing the services that publish events.

**Two concrete challenges:**

1. **Timing / ordering.** Because delivery happens in the background, a student might briefly see an enrollment change before the matching notification shows up, and events can arrive out of order. The design has to cope with that and avoid sending duplicates.
2. **More moving parts.** Running a message queue (with its retries, dead-letter queue and monitoring) is more complex to set up and look after than a plain function call, which is real extra work on top of CampusConnect's existing course/enrollment system.

---

## Section 3 - Low-Level Design

### Interface: `DeliveryChannel`

Method signatures only (no implementation):

- `send(notification: Notification) -> DeliveryResult`
- `channel_name() -> str`
- `supports(preference: UserPreference) -> bool`

**What this interface gives us:** the dispatcher only knows about the `DeliveryChannel` interface, not about any specific channel. So an `EmailChannel`, `PushChannel` or `InAppChannel` can be added or swapped in without changing the dispatcher at all - each new channel just has to provide those three methods. This means we can change how notifications are delivered without touching the code that decides what to send.

### Class 1: `Notification`

- **Attributes:**
  - `notification_id: str`
  - `recipient_id: int`
  - `event_type: str` (e.g. `"ASSIGNMENT_POSTED"`, `"ENROLLMENT_CHANGED"`)
  - `payload: dict` (title, body, and the related course or assignment id)
  - `created_at: datetime`
  - `status: str` (`"queued" | "sent" | "read" | "failed"`)
- **Methods:**
  - `mark_sent() -> None`
  - `mark_read() -> None`
  - `mark_failed(reason: str) -> None`
  - `to_feed_item() -> dict`
- **SOLID principle: Single Responsibility Principle (SRP).** `Notification` only holds one notification's data and updates its own status. It doesn't know how to deliver itself or which channel to use, so it has just one job and one reason to change.

### Class 2: `NotificationDispatcher`

- **Attributes:**
  - `channels: List[DeliveryChannel]`
  - `preferences: UserPreferenceRepository`
  - `repo: NotificationRepository`
- **Methods:**
  - `dispatch(notification: Notification) -> DeliveryResult`
  - `register_channel(channel: DeliveryChannel) -> None`
  - `select_channels(preference: UserPreference) -> List[DeliveryChannel]`
- **SOLID principles: Open/Closed (OCP) and Dependency Inversion (DIP).** You can add new channels with `register_channel` without changing the dispatcher (OCP), and the dispatcher depends on the `DeliveryChannel` interface instead of specific channel classes (DIP), so the high-level sending logic never hard-codes a particular delivery method.

---

## Section 4 - Scalability Plan

**Bottleneck:** the number of notifications to **deliver during busy periods**. The worst case is results day or an assignment posted to a big course, where one event turns into hundreds or thousands of separate sends (email/push), and each send is its own network call with its own delay and rate limits.

**Scaling choice: horizontal scaling.** Each notification is independent, so the work splits up easily - adding more worker instances that each pull from the queue increases how much we can send at once. That fits an uneven, spiky workload better than vertical scaling, because one bigger machine still has a single network exit and a hard ceiling, and you'd be paying for that big machine even during the long quiet periods.

**Elasticity policy:** scale **out** when the queue gets backed up - for example, add workers when there are more than about 1,000 notifications waiting or messages have been waiting longer than about 30 seconds. Scale **in** (remove workers) once the queue has stayed nearly empty and CPU has been low for a while (say 10 minutes), so we don't keep adding and removing workers over a short spike.

**Load-balancing algorithm: Least Connection.** Incoming notification-generation requests should go to the server that currently has the fewest requests in progress. The work is uneven - a fan-out to a 500-student course is much bigger than a single enrollment change - so Round Robin would keep sending new requests to a server that's already stuck on a huge job. Least Connection sends new requests to whichever server is least busy, which suits this uneven traffic.

---

## Section 5 - Cloud Deployment Recommendation

**Deployment model: public cloud.** **Service model: PaaS.**

**Why the public cloud (two NIST characteristics):**

- **Rapid elasticity** - CampusConnect's notification load is very spiky (quiet most of the term, big spikes on results day and near deadlines). A public cloud lets us add delivery workers and remove them automatically to match that, so we aren't paying all year for the capacity we only need on peak days.
- **On-demand self-service** - the team can add more queues, workers or a bigger database themselves through a console or API whenever they need to, without ordering hardware. That's what a small university-platform team needs to move quickly.

**Why PaaS (one named cloud challenge):**

- **Challenge: limited control / operational work.** With **PaaS** (a managed app platform plus a managed queue and managed database), the provider handles the OS patching, runtime upgrades, queue maintenance and database backups. For a small team that removes a lot of routine work and lets us focus on the notification logic itself. The trade-off is that we get less low-level control than with IaaS, but that's fine here because a notifications service doesn't need any special low-level settings, so we're not giving up control we'd actually use.