---
status: active
branch: claude/new-session-xeyz5n
pr:
---

# The harness never exercises the installer's curl branch

## Intent

`test-install.sh` points `METIS_SOURCE` at a local directory in every case,
so only the `cp` branch of `install.sh`'s source fetch runs under test. The
curl branch was proven by hand in review rounds 2–4 of issue 0013 (against a
local HTTP server), but that proof lives in review logs — a regression in
the curl arm would pass the suite.

(This issue originally also carried the broken-settings.json edges from
round 4; the human pulled those into run 0013 itself — the installer now
checks the file up front and aborts — so only this gap remains.)

Wanted behaviour: a break in the installer's curl branch makes the suite
fail.

Acceptance criteria:

1. The test harness exercises the curl branch of the source fetch — e.g.
   `METIS_SOURCE` pointing at a local HTTP server — and a broken curl arm
   fails the suite, shown by exit code.
2. The harness still needs no network beyond the loopback interface.

## Plan

## Tasks

## Decisions

## Log

## Checkpoints

### Before implementation

- Does this match what was asked? Yes — one narrow gap, two criteria, a
  test-only change; the 0013 review already proved the approach (local
  HTTP server on loopback) works by hand. Dispatched to the implementer.
- What surprised me? Nothing yet.
- What am I assuming without having verified it? That a loopback HTTP
  server is available on this machine without new dependencies (python3
  is already an installer precondition, so `python3 -m http.server` is
  the obvious candidate) — the implementer verifies.

### Before the PR

- Does this match what was asked?
- What surprised me?
- What am I assuming without having verified it?

## Retro
