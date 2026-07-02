# Memory — lessons that compound

An AI agent forgets everything between sessions. Left alone, it makes the same mistake in June that it
made in April. So the system gives it a memory: after each session, the hard-won lesson gets written down
as a small file, and the next session reads the index and doesn't step on the same rake twice.

## How it's stored

One fact per file. Small, focused, and linked to related ones. Each file has a short header (a name, a
one-line summary, a type) and a body with the lesson.

Why one fact per file instead of one big notes document:

- **It's searchable.** The next session can pull in exactly the three lessons relevant to today's task,
  not wade through a 40-page log.
- **It's honest about staleness.** If a lesson turns out wrong, you delete that one file. In a big
  document, wrong advice just sits there forever.
- **It links.** A lesson about a login bug points to the lesson about the token table points to the
  lesson about the mobile keychain. Related scars connect, so the whole picture surfaces together.

## The types of memory

- **User** — who I'm working with, how they like to work, what they've corrected before.
- **Feedback** — a piece of guidance, with the *why* attached so it's not applied blindly.
- **Project** — an ongoing goal or constraint that isn't obvious from the code.
- **Reference** — a pointer to something external (a dashboard, a doc, a ticket).

## Real lessons this produced (sanitized)

These are actual memory entries, cleaned of product specifics. Each one is a bug or an incident that
won't repeat because it's written down:

- *"A container restart does not re-read environment variables. After rotating a secret you need a full
  redeploy, or the app keeps using the dead key."*
- *"Diagnose auth bugs from the production token table first. Check what actually happened to the tokens
  before theorizing about the client."*
- *"Verify output coverage against the source duration. A list of bullet points is not proof that the
  whole thing was covered — assert the timestamps reach the end."*
- *"Two deploys against the same branch at once produce false failures in the report. If production is
  actually healthy, don't re-deploy blindly."*

## Why this is the quiet superpower

Most of the value of an experienced engineer is the list of mistakes they've already made and won't make
again. This is that list, written down, and read back every session. The system doesn't just build — it
learns, and the learning sticks.
