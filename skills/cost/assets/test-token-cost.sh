#!/bin/bash
# Tests for token-cost.py — the command that reports what a run cost.
#
# Every case builds a scratch ~/.claude holding hand-made transcripts and runs
# the command against it with HOME, the session id and the working directory
# pointing at that scratch. The real ~/.claude and the real transcripts are
# never read and never touched. Exit 0 = all cases pass.
#
# The command is invoked as `python3 token-cost.py` with no arguments, from the
# project directory whose transcripts are to be reported.
#
# Numbers in the expectations are normalised for thousands separators before
# they are looked for: `1,234,567` and `1234567` both count as 1234567.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cmd="$here/token-cost.py"
repo_root="$(cd "$here/../../.." && pwd)"

# The fixture path becomes a directory name under ~/.claude/projects with every
# `/` turned into `-`. A path holding characters whose sanitising is not
# obvious (dots, underscores, upper case) would make the fixture ambiguous, so
# a scratch base that carries any of them is dropped for a plain one.
base=$(mktemp -d)
case "$base" in
  *[!a-z0-9/-]*) rmdir "$base" 2>/dev/null; base="/tmp/token-cost-tests-$$-$RANDOM"; mkdir -p "$base" ;;
esac
trap 'rm -rf "$base"' EXIT

failures=0
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
pass() { echo "ok:   $1"; }

# Shows what the command printed — only called when a case has failed.
show() {
  echo "      --- command output (first 40 lines) ---"
  printf '%s\n' "$1" | head -40 | sed 's/^/      /'
  if [ -s "$base/last-stderr" ]; then
    echo "      --- stderr ---"
    head -10 "$base/last-stderr" | sed 's/^/      /'
  fi
}

# --- helpers ----------------------------------------------------------------

# Runs the command. $1 = script, $2 = HOME, $3 = working directory,
# $4 = session id. Prints stdout with thousands separators removed; stderr
# lands in $base/last-stderr; the exit status is the command's own.
run_cost() {
  local out status
  out=$( cd "$3" && HOME="$2" CLAUDE_PROJECT_DIR="$3" \
         CLAUDE_CODE_SESSION_ID="$4" CLAUDE_SESSION_ID="$4" \
         python3 "$1" 2>"$base/last-stderr" )
  status=$?
  printf '%s' "$out" | python3 -c \
    'import re,sys; sys.stdout.write(re.sub(r"(?<=[0-9])[,_](?=[0-9])", "", sys.stdin.read()))'
  return $status
}

# Runs the command with the session variables in a chosen state: both are
# removed from the environment first, then every NAME=value given from $4 on is
# put back — `CLAUDE_SESSION_ID=` puts it back empty. $1 = script, $2 = HOME,
# $3 = working directory. Everything else matches run_cost. Prints stdout and
# stderr together with thousands separators removed, since the report that the
# session cannot be identified may go to either; stderr also lands in
# $base/last-stderr. The exit status is the command's own.
run_cost_session_env() {
  local script="$1" home="$2" cwd="$3"
  shift 3
  local out status
  out=$( cd "$cwd" && HOME="$home" CLAUDE_PROJECT_DIR="$cwd" \
         env -u CLAUDE_SESSION_ID -u CLAUDE_CODE_SESSION_ID "$@" \
         python3 "$script" 2>"$base/last-stderr" )
  status=$?
  { printf '%s\n' "$out"; cat "$base/last-stderr"; } | python3 -c \
    'import re,sys; sys.stdout.write(re.sub(r"(?<=[0-9])[,_](?=[0-9])", "", sys.stdin.read()))'
  return $status
}

# Runs the command with neither session variable set — the case where nothing
# tells it which session is running. $1 = script, $2 = HOME, $3 = working dir.
run_cost_no_session() { run_cost_session_env "$1" "$2" "$3"; }

# $1 = text. True when some line naming a session reports that the running one
# cannot be identified.
reports_no_session() {
  printf '%s\n' "$1" | grep -i 'session' \
    | grep -Eqi "cannot|can't|could not|couldn't|unable|unknown|unidentif|not identif|no session|not set|unset|missing|empty|absent|require"
}

# $1 = text, $2 = number. True when the number stands in the text on its own —
# not as part of a longer number and not behind a decimal point.
has_num() { printf '%s' "$1" | grep -Eq "(^|[^0-9.])$2([^0-9]|\$)"; }

# $1 = text, $2 = substring, $3 = number. True when some line holding the
# substring also holds the number on its own.
line_has_num() {
  printf '%s\n' "$1" | grep -F -- "$2" | grep -Eq "(^|[^0-9.])$3([^0-9]|\$)"
}

# $1 = text, $2 = substring, $3 = extended regex (case-insensitive). True when
# some line holding the substring also matches the regex.
line_matches() { printf '%s\n' "$1" | grep -F -- "$2" | grep -Eqi -- "$3"; }

# $1 = text, $2 = number, $3 = regex. True when some line holding the number on
# its own also matches the regex.
numline_matches() {
  printf '%s\n' "$1" | grep -E "(^|[^0-9.])$2([^0-9]|\$)" | grep -Eqi -- "$3"
}

# Every file, directory and link under $1 with its size, mtime and content.
snapshot() {
  find "$1" -mindepth 0 -printf '%y %P %s %T@\n' 2>/dev/null | sort
  find "$1" -type f -exec md5sum {} + 2>/dev/null | sort
}

# --- the fixture builder ----------------------------------------------------
cat >"$base/mkfix.py" <<'MKFIX'
"""Builds transcript fixtures for test-token-cost.sh.

Usage: mkfix.py <case> <home> <cwd>

Writes JSONL transcripts under <home>/.claude/projects/<sanitised cwd>/ and
prints the figures the suite asserts on as KEY=value lines.
"""
import json, os, shlex, sys

VERSION = "2.1.220"


def sanitise(path):
    return path.replace("/", "-")


def text(s):
    return {"type": "text", "text": s}


def thinking():
    return {"type": "thinking", "thinking": "considering", "signature": "sig"}


def bash_use(tid, marker):
    return {"type": "tool_use", "id": tid, "name": "Bash",
            "input": {"command": marker + " --probe",
                      "description": marker + " probe"}}


def agent_use(tid, agent_type, desc, prompt):
    return {"type": "tool_use", "id": tid, "name": "Agent",
            "input": {"subagent_type": agent_type, "description": desc,
                      "prompt": prompt, "run_in_background": False}}


def tool_result(tid, marker, size):
    return {"tool_use_id": tid, "type": "tool_result",
            "content": marker + " " + ("x" * size)}


class Transcript(object):
    """One transcript: the main session's, or one dispatch's."""

    def __init__(self, session, cwd, agent_id=None, agent_type=None):
        self.session, self.cwd = session, cwd
        self.agent_id, self.agent_type = agent_id, agent_type
        self.recs, self.prev, self.n = [], None, 0
        self.w = self.r = 0
        self.w_naive = self.r_naive = self.out_naive = 0
        self.out_max, self.reqs, self.records = {}, [], 0

    def _base(self, typ):
        self.n += 1
        uid = "%s-%06d" % (self.session[:8], self.n)
        rec = {"parentUuid": self.prev, "uuid": uid, "type": typ,
               "timestamp": "2026-07-31T09:%02d:%02d.000Z" % (self.n // 60 % 60, self.n % 60),
               "sessionId": self.session, "cwd": self.cwd,
               "version": VERSION, "gitBranch": "fixture-branch",
               "userType": "external", "entrypoint": "remote_desktop"}
        if self.agent_id:
            rec["isSidechain"] = True
            rec["agentId"] = self.agent_id
        self.prev = uid
        return rec

    def user(self, content):
        rec = self._base("user")
        rec["message"] = {"role": "user", "content": content}
        self.recs.append(rec)

    def request(self, req, blocks, w, r, outs):
        """One model call, written as one transcript record per content block.

        Every record of the call repeats the call's cache figures verbatim, as
        the real transcripts do; output_tokens may differ between them.
        """
        assert len(blocks) == len(outs)
        for block, out in zip(blocks, outs):
            rec = self._base("assistant")
            rec["requestId"] = req
            if self.agent_type:
                rec["attributionAgent"] = self.agent_type
            rec["message"] = {
                "model": "claude-opus-5", "id": "msg_" + req, "type": "message",
                "role": "assistant", "content": [block], "stop_reason": None,
                "usage": {"input_tokens": 2,
                          "cache_creation_input_tokens": w,
                          "cache_read_input_tokens": r,
                          "cache_creation": {"ephemeral_5m_input_tokens": w,
                                             "ephemeral_1h_input_tokens": 0},
                          "output_tokens": out,
                          "service_tier": "standard"}}
            self.recs.append(rec)
            self.w_naive += w
            self.r_naive += r
            self.out_naive += out
            self.records += 1
        self.w += w
        self.r += r
        self.out_max[req] = max(outs)
        self.reqs.append(req)

    @property
    def steps(self):
        return len(set(self.reqs))

    @property
    def out_max_sum(self):
        return sum(self.out_max.values())

    def write(self, path, mtime=None):
        d = os.path.dirname(path)
        if d:
            os.makedirs(d, exist_ok=True)
        with open(path, "w") as fh:
            for rec in self.recs:
                fh.write(json.dumps(rec) + "\n")
        if mtime is not None:
            os.utime(path, (mtime, mtime))


def meta(path, agent_type, desc, tool_use_id, mtime=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        json.dump({"agentType": agent_type, "description": desc,
                   "toolUseId": tool_use_id, "spawnDepth": 1}, fh)
    if mtime is not None:
        os.utime(path, (mtime, mtime))


def pdir(home, cwd):
    return os.path.join(home, ".claude", "projects", sanitise(cwd))


def sub(home, cwd, session, agent_id):
    return os.path.join(pdir(home, cwd), session, "subagents", "agent-%s" % agent_id)


def emit(pairs):
    for key, value in pairs:
        print("%s=%s" % (key, shlex.quote(str(value))))


# --- the cases --------------------------------------------------------------

def case_basic(home, cwd):
    """A session with two dispatches: the shape criteria 1, 2 and 9 describe."""
    s = "aaaaaaaa-1111-2222-3333-444444444444"
    d1, d2 = "a1111111111111111", "a2222222222222222"
    d1_desc = "Review the diff for issue zulu"
    d2_desc = "Write failing tests for issue yankee"

    m = Transcript(s, cwd)
    m.user("start the run")
    m.request("req_m1", [text("starting")], 210000, 0, [40])
    m.request("req_m2", [text("dispatching"), agent_use("toolu_d1", "reviewer", d1_desc, "reviewer prompt")],
              1000, 210000, [7, 700])
    m.user([tool_result("toolu_d1", "reviewer verdict", 40)])
    m.request("req_m3", [agent_use("toolu_d2", "test-author", d2_desc, "test-author prompt")],
              2000, 211000, [500])
    m.user([tool_result("toolu_d2", "tests written", 40)])
    m.request("req_m4", [text("done")], 3000, 213000, [300])
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))

    a = Transcript(s, cwd, d1, "reviewer")
    a.user("reviewer prompt")
    a.request("req_a1", [thinking(), text("looking")], 330000, 0, [3, 200])
    a.request("req_a2", [text("still looking")], 20000, 330000, [300])
    a.request("req_a3", [text("verdict")], 7000, 350000, [400])
    a.write(sub(home, cwd, s, d1) + ".jsonl")
    meta(sub(home, cwd, s, d1) + ".meta.json", "reviewer", d1_desc, "toolu_d1")

    b = Transcript(s, cwd, d2, "test-author")
    b.user("test-author prompt")
    b.request("req_b1", [text("writing")], 140000, 0, [100])
    b.request("req_b2", [text("failing as wanted")], 9000, 140000, [250])
    b.write(sub(home, cwd, s, d2) + ".jsonl")
    meta(sub(home, cwd, s, d2) + ".meta.json", "test-author", d2_desc, "toolu_d2")

    emit([("SESSION", s),
          ("MAIN_W", m.w), ("MAIN_R", m.r), ("MAIN_STEPS", m.steps),
          ("D1_W", a.w), ("D1_R", a.r), ("D1_STEPS", a.steps), ("D1_DESC", d1_desc),
          ("D2_W", b.w), ("D2_R", b.r), ("D2_STEPS", b.steps), ("D2_DESC", d2_desc)])


def case_nodispatch(home, cwd):
    """A session that dispatched nothing at all."""
    s = "dddddddd-1111-2222-3333-444444444444"
    m = Transcript(s, cwd)
    m.user("a run without a single dispatch")
    m.request("req_n1", [text("first")], 150000, 0, [120])
    carried = 150000
    for i in range(2, 14):
        m.request("req_n%d" % i, [text("step %d" % i)], 1000, carried, [10 * i])
        carried += 1000
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))
    emit([("SESSION", s), ("MAIN_W", m.w), ("MAIN_R", m.r), ("MAIN_STEPS", m.steps)])


def case_decoys(home, cwd):
    """The current session, plus transcripts the command must not read."""
    s = "eeeeeeee-1111-2222-3333-444444444444"
    d = "a3333333333333333"
    desc = "Review the current session"
    m = Transcript(s, cwd)
    m.user("the running session")
    m.request("req_c1", [agent_use("toolu_d3", "reviewer", desc, "reviewer prompt")], 50000, 0, [80])
    m.user([tool_result("toolu_d3", "verdict", 30)])
    m.request("req_c2", [text("done")], 1000, 50000, [90])
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))
    a = Transcript(s, cwd, d, "reviewer")
    a.user("reviewer prompt")
    a.request("req_c3", [text("reviewing")], 60000, 0, [70])
    a.request("req_c4", [text("verdict")], 3000, 60000, [60])
    a.write(sub(home, cwd, s, d) + ".jsonl")
    meta(sub(home, cwd, s, d) + ".meta.json", "reviewer", desc, "toolu_d3")

    old = 1000000000  # a plain old mtime: the decoys are not the newest files

    # Decoy 1: an earlier session of the same project.
    s2, d2 = "ffffffff-1111-2222-3333-444444444444", "a4444444444444444"
    m2 = Transcript(s2, cwd)
    m2.user("an earlier session")
    m2.request("req_g1", [agent_use("toolu_g1", "ghost-agent-a", "ghost-dispatch-alpha", "ghost")],
               9876543, 0, [11])
    m2.write(os.path.join(pdir(home, cwd), s2 + ".jsonl"), old)
    g = Transcript(s2, cwd, d2, "ghost-agent-a")
    g.user("ghost")
    g.request("req_g2", [text("ghosting")], 9876543, 9876543, [12])
    g.write(sub(home, cwd, s2, d2) + ".jsonl", old)
    meta(sub(home, cwd, s2, d2) + ".meta.json", "ghost-agent-a", "ghost-dispatch-alpha", "toolu_g1", old)

    # Decoy 2: a session of another project.
    other = os.path.join(os.path.dirname(cwd), "proj-b")
    os.makedirs(other, exist_ok=True)
    s3, d3 = "99999999-1111-2222-3333-444444444444", "a5555555555555555"
    m3 = Transcript(s3, other)
    m3.user("another project")
    m3.request("req_h1", [agent_use("toolu_h1", "ghost-agent-b", "ghost-dispatch-beta", "ghost")],
               8765432, 0, [13])
    m3.write(os.path.join(pdir(home, other), s3 + ".jsonl"), old)
    h = Transcript(s3, other, d3, "ghost-agent-b")
    h.user("ghost")
    h.request("req_h2", [text("ghosting")], 8765432, 8765432, [14])
    h.write(sub(home, other, s3, d3) + ".jsonl", old)
    meta(sub(home, other, s3, d3) + ".meta.json", "ghost-agent-b", "ghost-dispatch-beta", "toolu_h1", old)

    emit([("SESSION", s), ("OTHER_CWD", other),
          ("MAIN_W", m.w), ("MAIN_R", m.r),
          ("D1_W", a.w), ("D1_R", a.r)])


def case_inflation(home, cwd):
    """41 records over 23 model calls, with output_tokens disagreeing inside a call."""
    s = "bbbbbbbb-1111-2222-3333-444444444444"
    d = "a6666666666666666"
    desc = "Review the inflated dispatch"
    m = Transcript(s, cwd)
    m.user("one dispatch, many records")
    m.request("req_i1", [agent_use("toolu_i1", "reviewer", desc, "reviewer prompt")], 1000, 0, [1])
    m.user([tool_result("toolu_i1", "verdict", 20)])
    m.request("req_i2", [text("done")], 1000, 1000, [1])
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))

    a = Transcript(s, cwd, d, "reviewer")
    a.user("reviewer prompt")
    # Call 1 and calls 2-18 are each written as two records; within a call the
    # two records report a placeholder output count and the real one.
    a.request("req_j1", [thinking(), text("starting")], 100000, 0, [3, 667])
    for i in range(2, 19):
        a.request("req_j%d" % i, [thinking(), text("step %d" % i)], 10000, 300000, [3, 667])
    for i in range(19, 24):
        a.request("req_j%d" % i, [text("step %d" % i)], 10000, 300000, [500])
    a.write(sub(home, cwd, s, d) + ".jsonl")
    meta(sub(home, cwd, s, d) + ".meta.json", "reviewer", desc, "toolu_i1")

    emit([("SESSION", s), ("DESC", desc),
          ("D_W", a.w), ("D_R", a.r), ("D_STEPS", a.steps),
          ("D_RECORDS", a.records),
          ("D_W_NAIVE", a.w_naive), ("D_R_NAIVE", a.r_naive),
          ("D_OUT_NAIVE", a.out_naive), ("D_OUT_MAX", a.out_max_sum)])


def case_columns(home, cwd):
    """One session, three token kinds, nothing to combine them with."""
    s = "cccccccc-1111-2222-3333-444444444444"
    m = Transcript(s, cwd)
    m.user("count the columns")
    m.request("req_k1", [text("first")], 100000, 0, [1000])
    m.request("req_k2", [text("second")], 10000, 100000, [2000])
    m.request("req_k3", [text("third")], 1000, 245000, [1400])
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))
    w, r, o = m.w, m.r, m.out_max_sum
    emit([("SESSION", s), ("W", w), ("R", r), ("O", o),
          ("SUM_WR", w + r), ("SUM_WRO", w + r + o),
          ("SUM_RO", r + o), ("SUM_WO", w + o),
          ("WEIGHTED", int(2 * w + 0.1 * r + 5 * o))])


def case_attribution(home, cwd):
    """A dispatch whose context is fed by named items, one call at a time."""
    s = "77777777-1111-2222-3333-444444444444"
    d = "a7777777777777777"
    desc = "Review the attribution fixture"

    m = Transcript(s, cwd)
    m.user("the main session reads a file of its own")
    m.request("req_p1", [bash_use("toolu_p1", "zqx-main-cmd")], 100000, 0, [50])
    m.user([tool_result("toolu_p1", "zqx-main-cmd", 4000)])
    m.request("req_p2", [agent_use("toolu_p2", "reviewer", desc, "reviewer prompt")], 90000, 100000, [60])
    m.user([tool_result("toolu_p2", "verdict", 30)])
    m.request("req_p3", [text("done")], 1000, 190000, [70])
    m.write(os.path.join(pdir(home, cwd), s + ".jsonl"))

    a = Transcript(s, cwd, d, "reviewer")
    a.user("reviewer prompt")
    # Call 1: only the prompt has entered the context, so its cache-write is
    # attributable to that one item.
    a.request("req_q1", [bash_use("toolu_q1", "zqx-multi-one"),
                         bash_use("toolu_q2", "zqx-multi-two"),
                         bash_use("toolu_q3", "zqx-multi-three")], 200000, 0, [3, 100, 100])
    a.user([tool_result("toolu_q1", "zqx-multi-one", 3000),
            tool_result("toolu_q2", "zqx-multi-two", 3000),
            tool_result("toolu_q3", "zqx-multi-three", 3000)])
    # Call 2: three results entered together — nothing here is attributable to
    # one of them alone.
    a.request("req_q2", [text("reading them")], 300000, 200000, [120])
    a.request("req_q3", [bash_use("toolu_q4", "zqx-solo-alpha")], 5000, 500000, [130])
    a.user([tool_result("toolu_q4", "zqx-solo-alpha", 9000)])
    a.request("req_q4", [text("done")], 260000, 505000, [140])
    a.write(sub(home, cwd, s, d) + ".jsonl")
    meta(sub(home, cwd, s, d) + ".meta.json", "reviewer", desc, "toolu_p2")

    emit([("SESSION", s), ("DESC", desc),
          ("D_W", a.w), ("D_R", a.r), ("D_STEPS", a.steps),
          ("SOLO_STEP_CALLED", 3), ("SOLO_STEP_ENTERED", 4),
          ("MEASURED_FIGURE", 200000)])


CASES = {"basic": case_basic, "nodispatch": case_nodispatch, "decoys": case_decoys,
         "inflation": case_inflation, "columns": case_columns,
         "attribution": case_attribution}

name, home, cwd = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(cwd, exist_ok=True)
os.makedirs(os.path.join(home, ".claude", "projects"), exist_ok=True)
CASES[name](home, cwd)
MKFIX

# Builds a fixture. $1 = case name, $2 = a name for the scratch. Sets HOME_DIR
# and CWD_DIR and eval's the figures the builder printed.
build() {
  HOME_DIR="$base/$2/home"
  CWD_DIR="$base/$2/proj-a"
  mkdir -p "$HOME_DIR" "$CWD_DIR"
  local vars
  vars=$(python3 "$base/mkfix.py" "$1" "$HOME_DIR" "$CWD_DIR") || {
    echo "fixture builder failed for case $1" >&2; exit 1; }
  eval "$vars"
}

# --- Case 1 (criterion 1): every dispatch is reported, with its type, its
# purpose, its model steps and its token counts ------------------------------
prior=$failures
build basic b1
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "dispatches: exit status $?, expected 0"
printf '%s' "$out" | grep -q 'reviewer' || fail "dispatches: the reviewer dispatch's agent type is not printed"
printf '%s' "$out" | grep -q 'test-author' || fail "dispatches: the test-author dispatch's agent type is not printed"
printf '%s' "$out" | grep -qF "$D1_DESC" || fail "dispatches: what the reviewer was dispatched for ('$D1_DESC') is not printed"
printf '%s' "$out" | grep -qF "$D2_DESC" || fail "dispatches: what the test-author was dispatched for ('$D2_DESC') is not printed"
line_has_num "$out" "reviewer" "$D1_W" || fail "dispatches: no reviewer row carries its cache-write $D1_W"
line_has_num "$out" "reviewer" "$D1_R" || fail "dispatches: no reviewer row carries its cache-read $D1_R"
line_has_num "$out" "reviewer" "$D1_STEPS" || fail "dispatches: no reviewer row carries its $D1_STEPS model steps"
line_has_num "$out" "test-author" "$D2_W" || fail "dispatches: no test-author row carries its cache-write $D2_W"
line_has_num "$out" "test-author" "$D2_R" || fail "dispatches: no test-author row carries its cache-read $D2_R"
line_has_num "$out" "test-author" "$D2_STEPS" || fail "dispatches: no test-author row carries its $D2_STEPS model steps"
[ $failures -eq $prior ] && pass "two dispatches: type, purpose, steps and token counts printed, exit 0" || show "$out"

# --- Case 2 (criterion 1): the command is documented ------------------------
prior=$failures
[ -f "$repo_root/skills/cost/SKILL.md" ] || fail "documented: skills/cost/SKILL.md does not exist"
grep -q 'token-cost.py' "$repo_root/skills/cost/SKILL.md" 2>/dev/null \
  || fail "documented: skills/cost/SKILL.md does not name token-cost.py"
[ $failures -eq $prior ] && pass "the command is documented by its skill page"

# --- Case 3 (criterion 2): the main session is reported in the same columns --
prior=$failures
build basic b2
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "main session: exit status $?, expected 0"
printf '%s' "$out" | grep -qi 'main' || fail "main session: nothing in the output names the main session"
line_has_num "$out" "ain" "$MAIN_W" || fail "main session: its row carries no cache-write $MAIN_W"
line_has_num "$out" "ain" "$MAIN_R" || fail "main session: its row carries no cache-read $MAIN_R"
line_has_num "$out" "ain" "$MAIN_STEPS" || fail "main session: its row carries no step count $MAIN_STEPS"
[ $failures -eq $prior ] && pass "main session reported in a dispatch's columns" || show "$out"

# --- Case 4 (criterion 2): a session that dispatched nothing ----------------
prior=$failures
build nodispatch b3
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "no dispatch: exit status $?, expected 0"
printf '%s' "$out" | grep -qi 'main' || fail "no dispatch: the main session is not reported"
line_has_num "$out" "ain" "$MAIN_W" || fail "no dispatch: the main session's cache-write $MAIN_W is missing"
line_has_num "$out" "ain" "$MAIN_R" || fail "no dispatch: the main session's cache-read $MAIN_R is missing"
line_has_num "$out" "ain" "$MAIN_STEPS" || fail "no dispatch: the main session's step count $MAIN_STEPS is missing"
[ $failures -eq $prior ] && pass "no dispatch at all: main session still reported, exit 0" || show "$out"

# --- Case 5 (criterion 2, boundary): an empty subagents directory -----------
prior=$failures
build nodispatch b4
mkdir -p "$HOME_DIR/.claude/projects/$(printf '%s' "$CWD_DIR" | tr '/' '-')/$SESSION/subagents"
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "empty subagents dir: exit status $?, expected 0"
line_has_num "$out" "ain" "$MAIN_R" || fail "empty subagents dir: the main session's cache-read $MAIN_R is missing"
[ $failures -eq $prior ] && pass "empty subagents directory: main session still reported, exit 0" || show "$out"

# --- Case 6 (criterion 3): nothing is written -------------------------------
prior=$failures
build decoys b5
before_home=$(snapshot "$HOME_DIR")
before_proj=$(snapshot "$base/b5")
before_cmd=$(snapshot "$here")
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "read-only: exit status $?, expected 0"
[ "$before_home" = "$(snapshot "$HOME_DIR")" ] || fail "read-only: something under the scratch HOME was created or modified"
[ "$before_proj" = "$(snapshot "$base/b5")" ] || fail "read-only: something under the project directories was created or modified"
[ "$before_cmd" = "$(snapshot "$here")" ] || fail "read-only: something next to the command itself was created or modified"
[ $failures -eq $prior ] && pass "no file created or modified" || show "$out"

# --- Case 7 (criterion 3): no other session's transcripts are read ----------
prior=$failures
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "other sessions: exit status $?, expected 0"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "other sessions: an earlier session of this project was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-alpha' && fail "other sessions: an earlier session's dispatch is reported"
printf '%s' "$out" | grep -q 'ghost-agent-b' && fail "other sessions: another project's session was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-beta' && fail "other sessions: another project's dispatch is reported"
has_num "$out" 9876543 && fail "other sessions: an earlier session's token figure 9876543 is in the output"
has_num "$out" 8765432 && fail "other sessions: another project's token figure 8765432 is in the output"
line_has_num "$out" "reviewer" "$D1_R" || fail "other sessions: the current session's own dispatch ($D1_R cache-read) is missing"
[ $failures -eq $prior ] && pass "only the current session's transcripts are read" || show "$out"

# --- Case 8 (criterion 6): steps are model calls, not transcript records ----
prior=$failures
build inflation b6
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "steps: exit status $?, expected 0"
line_has_num "$out" "reviewer" "$D_STEPS" \
  || fail "steps: the dispatch's row does not carry its $D_STEPS model calls"
line_has_num "$out" "reviewer" "$D_RECORDS" \
  && fail "steps: the dispatch's row carries $D_RECORDS — the number of transcript records, not of model calls"
has_num "$out" "$D_W" || fail "steps: the dispatch's cache-write $D_W (once per call) is missing"
has_num "$out" "$D_R" || fail "steps: the dispatch's cache-read $D_R (once per call) is missing"
has_num "$out" "$D_W_NAIVE" && fail "steps: cache-write $D_W_NAIVE is the per-record sum — one call's figures counted several times"
has_num "$out" "$D_R_NAIVE" && fail "steps: cache-read $D_R_NAIVE is the per-record sum — one call's figures counted several times"
[ $failures -eq $prior ] && pass "step count and token counts are per model call, not per record" || show "$out"

# --- Case 9 (criterion 5): the unreliable field is marked, not counted ------
prior=$failures
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "unreliable field: exit status $?, expected 0"
printf '%s\n' "$out" | grep -i 'output' | grep -qi 'unreliab' \
  || fail "unreliable field: nothing in the output marks the output-token field as unreliable"
has_num "$out" "$D_OUT_NAIVE" \
  && fail "unreliable field: $D_OUT_NAIVE is printed — the output tokens added up across the records of a call"
[ $failures -eq $prior ] && pass "the unreliable output-token field is marked as such" || show "$out"

# --- Case 10 (criterion 9): three raw columns, no combined total ------------
prior=$failures
build columns b7
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "columns: exit status $?, expected 0"
printf '%s' "$out" | grep -Eqi 'cache[-_ ]?write' || fail "columns: no cache-write column is labelled"
printf '%s' "$out" | grep -Eqi 'cache[-_ ]?read' || fail "columns: no cache-read column is labelled"
printf '%s' "$out" | grep -Eqi 'output' || fail "columns: no output column is labelled"
has_num "$out" "$W" || fail "columns: the cache-write count $W is missing"
has_num "$out" "$R" || fail "columns: the cache-read count $R is missing"
has_num "$out" "$SUM_WR" && fail "columns: $SUM_WR is cache-write plus cache-read — a combined total"
has_num "$out" "$SUM_WRO" && fail "columns: $SUM_WRO is all three kinds added up — a combined total"
has_num "$out" "$SUM_RO" && fail "columns: $SUM_RO is cache-read plus output — a combined total"
has_num "$out" "$SUM_WO" && fail "columns: $SUM_WO is cache-write plus output — a combined total"
has_num "$out" "$WEIGHTED" && fail "columns: $WEIGHTED is the weighted total (write x2, read x0.1, output x5)"
[ $failures -eq $prior ] && pass "cache-write, cache-read and output stay separate raw columns" || show "$out"

# --- Case 11 (criterion 7): grouped breakdown and the most expensive items --
prior=$failures
build attribution b8
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "breakdown: exit status $?, expected 0"
printf '%s' "$out" | grep -q 'zqx-solo-alpha' \
  || fail "breakdown: the dispatch's most expensive item (zqx-solo-alpha) is not among the items printed"
printf '%s\n' "$out" | grep -F 'zqx-solo-alpha' \
  | grep -Eq "(^|[^0-9.])($SOLO_STEP_CALLED|$SOLO_STEP_ENTERED)([^0-9]|\$)" \
  || fail "breakdown: the line for zqx-solo-alpha names no step (expected $SOLO_STEP_CALLED or $SOLO_STEP_ENTERED)"
printf '%s' "$out" | grep -q 'zqx-multi-one' \
  || fail "breakdown: the item zqx-multi-one is not among the items printed"
printf '%s\n' "$out" | grep -Ei 'bash|shell|tool|command' | grep -v 'zqx-' | grep -Eq '[0-9]{5,}' \
  || fail "breakdown: no grouped line — a kind of thing with a token figure and no single item's name"
printf '%s' "$out" | grep -q 'zqx-main-cmd' \
  || fail "breakdown: the main session gets no item breakdown (zqx-main-cmd is missing)"
[ $failures -eq $prior ] && pass "grouped breakdown and most expensive items, each with its step" || show "$out"

# --- Case 12 (criterion 8): split figures estimated, single ones measured ---
prior=$failures
out=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "attribution: exit status $?, expected 0"
numline_matches "$out" "$MEASURED_FIGURE" 'measur' \
  || fail "attribution: $MEASURED_FIGURE is the one call's cache-write with a single item entering — it is not marked as measured"
line_matches "$out" "zqx-multi-one" 'estimat' \
  || fail "attribution: zqx-multi-one entered together with two other items — its figure is not marked as estimated"
[ $failures -eq $prior ] && pass "split figures marked estimated, single-item figures marked measured" || show "$out"

# --- Case 13 (criterion 10): the command does not depend on this repository -
prior=$failures
build basic b9
elsewhere="$base/elsewhere/metis-plugin/skills"
mkdir -p "$elsewhere"
if cp -r "$repo_root/skills/cost" "$elsewhere/" 2>/dev/null; then
  copy="$elsewhere/cost/assets/token-cost.py"
  in_repo=$(run_cost "$cmd" "$HOME_DIR" "$CWD_DIR" "$SESSION")
  copied=$(run_cost "$copy" "$HOME_DIR" "$CWD_DIR" "$SESSION") || fail "elsewhere: exit status $?, expected 0"
  # Only the data has to match: a run may name the script it was invoked as.
  strip() { sed -e "s#$here#SCRIPTDIR#g" -e "s#$elsewhere/cost/assets#SCRIPTDIR#g"; }
  a=$(printf '%s' "$in_repo" | strip)
  b=$(printf '%s' "$copied" | strip)
  [ "$a" = "$b" ] || fail "elsewhere: the copy outside this repository prints something else than the copy inside it"
  printf '%s' "$copied" | grep -qF "$repo_root" \
    && fail "elsewhere: the output names a path inside this repository's working tree"
  grep -qF "$repo_root" "$copy" 2>/dev/null \
    && fail "elsewhere: the command's own source hard-codes a path inside this repository's working tree"
else
  fail "elsewhere: skills/cost could not be copied out of the repository"
fi
[ $failures -eq $prior ] && pass "same output from a copy outside this repository" || show "${copied:-}"

# --- Case 14 (criterion 4): the numbers are in the issue's record -----------
prior=$failures
issue=$(ls "$repo_root"/docs/issues/0025-*.md 2>/dev/null | head -1)
if [ -z "$issue" ]; then
  fail "record: the issue file docs/issues/0025-*.md was not found"
else
  python3 - "$issue" <<'PY' || fail "record: the issue's record holds no per-dispatch numbers together with the command that produced them"
import re, sys
lines = open(sys.argv[1]).read().splitlines()
# Everything after the Intent is the record: Plan, Tasks, Decisions, Log,
# Checkpoints, Retro. The Intent's own premise table does not count.
start = None
for i, l in enumerate(lines):
    if l.startswith("## ") and l.strip() != "## Intent" and "## Intent" in lines[:i]:
        start = i
        break
if start is None:
    sys.exit(1)
record = lines[start:]
agents = ("reviewer", "test-author", "implementer", "researcher", "main")
named = any("token-cost.py" in l for l in record)
rows = [l for l in record
        if any(a in l for a in agents)
        and len(re.findall(r"(?<![0-9.])[0-9][0-9,]{2,}", l)) >= 2]
sys.exit(0 if named and rows else 1)
PY
fi
[ $failures -eq $prior ] && pass "the per-dispatch numbers and the command are in the issue's record"

# --- Case 15 (criterion 3): neither session variable is set -----------------
# Nothing names the running session, so no transcript in the project directory
# is known to be the current one. Guessing one would report a session the
# command was not asked about; it says so and fails instead.
prior=$failures
build decoys b10
before_home=$(snapshot "$HOME_DIR")
before_proj=$(snapshot "$base/b10")
out=$(run_cost_no_session "$cmd" "$HOME_DIR" "$CWD_DIR") \
  && fail "no session id: exit status 0, expected non-zero — the session cannot be identified"
printf '%s\n' "$out" | grep -qi 'session' || fail "no session id: nothing in the output mentions the session"
reports_no_session "$out" || fail "no session id: nothing reports that the running session cannot be identified"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "no session id: an earlier session of this project was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-alpha' && fail "no session id: an earlier session's dispatch is reported"
printf '%s' "$out" | grep -q 'ghost-agent-b' && fail "no session id: another project's session was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-beta' && fail "no session id: another project's dispatch is reported"
has_num "$out" 9876543 && fail "no session id: an earlier session's token figure 9876543 is in the output"
has_num "$out" 8765432 && fail "no session id: another project's token figure 8765432 is in the output"
has_num "$out" "$MAIN_W" && fail "no session id: a session was guessed — its main cache-write $MAIN_W is reported"
has_num "$out" "$D1_R" && fail "no session id: a session was guessed — its dispatch's cache-read $D1_R is reported"
[ "$before_home" = "$(snapshot "$HOME_DIR")" ] || fail "no session id: something under the scratch HOME was created or modified"
[ "$before_proj" = "$(snapshot "$base/b10")" ] || fail "no session id: something under the project directories was created or modified"
[ $failures -eq $prior ] && pass "neither session variable set: reports it cannot identify the session, exits non-zero" || show "$out"

# --- Case 16 (criterion 3, boundary): neither variable set, one transcript --
# The project directory holds a single session's transcript. It is still not
# known to be the running one, so the answer is the same as with many.
prior=$failures
build nodispatch b11
out=$(run_cost_no_session "$cmd" "$HOME_DIR" "$CWD_DIR") \
  && fail "no session id, one transcript: exit status 0, expected non-zero"
reports_no_session "$out" || fail "no session id, one transcript: nothing reports that the running session cannot be identified"
has_num "$out" "$MAIN_W" && fail "no session id, one transcript: the only session was guessed — its cache-write $MAIN_W is reported"
has_num "$out" "$MAIN_R" && fail "no session id, one transcript: the only session was guessed — its cache-read $MAIN_R is reported"
[ $failures -eq $prior ] && pass "neither session variable set with a single transcript: still no guess, exits non-zero" || show "$out"

# --- Case 17 (criterion 3): neither variable set, newest is another session -
# Same as case 15, but the running session's transcripts are the oldest files
# in the project directory. Whatever a guess would fall back on, it lands on a
# session that is not the running one.
prior=$failures
build decoys b12
projdir="$HOME_DIR/.claude/projects/$(printf '%s' "$CWD_DIR" | tr '/' '-')"
find "$projdir/$SESSION.jsonl" "$projdir/$SESSION" -exec touch -t 199809090909 {} + \
  || fail "newest is another session: the running session's transcripts could not be aged"
newest=$(find "$projdir" -name '*.jsonl' -printf '%T@ %p\n' | sort -n | tail -1)
case "$newest" in
  *"$SESSION"*) fail "newest is another session: the fixture still has the running session as the newest transcript" ;;
esac
out=$(run_cost_no_session "$cmd" "$HOME_DIR" "$CWD_DIR") \
  && fail "newest is another session: exit status 0, expected non-zero"
reports_no_session "$out" || fail "newest is another session: nothing reports that the running session cannot be identified"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "newest is another session: an earlier session of this project was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-alpha' && fail "newest is another session: an earlier session's dispatch is reported"
has_num "$out" 9876543 && fail "newest is another session: an earlier session's token figure 9876543 is in the output"
has_num "$out" "$MAIN_W" && fail "newest is another session: a session was guessed — its main cache-write $MAIN_W is reported"
has_num "$out" "$D1_R" && fail "newest is another session: a session was guessed — its dispatch's cache-read $D1_R is reported"
[ $failures -eq $prior ] && pass "neither session variable set with a newer foreign transcript: no foreign session read, exits non-zero" || show "$out"

# --- Case 18 (criterion 3, boundary): both variables set but empty ----------
# An empty id names no session, so it counts as not set: same answer as case 15.
prior=$failures
build decoys b13
before_home=$(snapshot "$HOME_DIR")
before_proj=$(snapshot "$base/b13")
out=$(run_cost_session_env "$cmd" "$HOME_DIR" "$CWD_DIR" CLAUDE_SESSION_ID= CLAUDE_CODE_SESSION_ID=) \
  && fail "empty session ids: exit status 0, expected non-zero — an empty id identifies no session"
reports_no_session "$out" || fail "empty session ids: nothing reports that the running session cannot be identified"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "empty session ids: an earlier session of this project was read"
printf '%s' "$out" | grep -q 'ghost-dispatch-alpha' && fail "empty session ids: an earlier session's dispatch is reported"
printf '%s' "$out" | grep -q 'ghost-agent-b' && fail "empty session ids: another project's session was read"
has_num "$out" 9876543 && fail "empty session ids: an earlier session's token figure 9876543 is in the output"
has_num "$out" "$MAIN_W" && fail "empty session ids: a session was guessed — its main cache-write $MAIN_W is reported"
has_num "$out" "$D1_R" && fail "empty session ids: a session was guessed — its dispatch's cache-read $D1_R is reported"
[ "$before_home" = "$(snapshot "$HOME_DIR")" ] || fail "empty session ids: something under the scratch HOME was created or modified"
[ "$before_proj" = "$(snapshot "$base/b13")" ] || fail "empty session ids: something under the project directories was created or modified"
[ $failures -eq $prior ] && pass "both session variables empty: reports it cannot identify the session, exits non-zero" || show "$out"

# --- Case 19 (criterion 3, boundary): CLAUDE_SESSION_ID empty, the other gone
# The empty one must not be taken for an id, and there is no second one to fall
# back to.
prior=$failures
build decoys b14
out=$(run_cost_session_env "$cmd" "$HOME_DIR" "$CWD_DIR" CLAUDE_SESSION_ID=) \
  && fail "empty CLAUDE_SESSION_ID: exit status 0, expected non-zero"
reports_no_session "$out" || fail "empty CLAUDE_SESSION_ID: nothing reports that the running session cannot be identified"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "empty CLAUDE_SESSION_ID: an earlier session of this project was read"
has_num "$out" 9876543 && fail "empty CLAUDE_SESSION_ID: an earlier session's token figure 9876543 is in the output"
has_num "$out" "$MAIN_W" && fail "empty CLAUDE_SESSION_ID: a session was guessed — its main cache-write $MAIN_W is reported"
has_num "$out" "$D1_R" && fail "empty CLAUDE_SESSION_ID: a session was guessed — its dispatch's cache-read $D1_R is reported"
[ $failures -eq $prior ] && pass "CLAUDE_SESSION_ID empty and CLAUDE_CODE_SESSION_ID absent: no guess, exits non-zero" || show "$out"

# --- Case 20 (criterion 3, boundary): the mirror of case 19 -----------------
prior=$failures
build decoys b15
out=$(run_cost_session_env "$cmd" "$HOME_DIR" "$CWD_DIR" CLAUDE_CODE_SESSION_ID=) \
  && fail "empty CLAUDE_CODE_SESSION_ID: exit status 0, expected non-zero"
reports_no_session "$out" || fail "empty CLAUDE_CODE_SESSION_ID: nothing reports that the running session cannot be identified"
printf '%s' "$out" | grep -q 'ghost-agent-a' && fail "empty CLAUDE_CODE_SESSION_ID: an earlier session of this project was read"
has_num "$out" 9876543 && fail "empty CLAUDE_CODE_SESSION_ID: an earlier session's token figure 9876543 is in the output"
has_num "$out" "$MAIN_W" && fail "empty CLAUDE_CODE_SESSION_ID: a session was guessed — its main cache-write $MAIN_W is reported"
has_num "$out" "$D1_R" && fail "empty CLAUDE_CODE_SESSION_ID: a session was guessed — its dispatch's cache-read $D1_R is reported"
[ $failures -eq $prior ] && pass "CLAUDE_CODE_SESSION_ID empty and CLAUDE_SESSION_ID absent: no guess, exits non-zero" || show "$out"

echo
if [ $failures -eq 0 ]; then echo "PASS: all cases"; else echo "FAIL: $failures case(s)"; exit 1; fi
