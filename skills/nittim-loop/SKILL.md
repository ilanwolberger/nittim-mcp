---
name: nittim-loop
description: Run the nittim Loop — a free, local self-review of the developer's own repository, using nittim's public checklist. Use when asked to self-audit, security-review, or "run the nittim loop" on a codebase the developer owns, especially before paying for a nittim audit. Nothing leaves the machine unless the developer separately says yes to that.
---

# The nittim Loop

A free self-review over a repository the developer owns, run entirely on
this session's own model. Nothing here uploads code anywhere. Follow it in
order.

## 1 · Read the checklist, live

Fetch `https://nittim.com/selfcheck.md` right now — never a cached or
remembered copy, this file is versioned and can change. Read it end to end
before touching any code. It defines the 13 review categories, the output
format, and the exact procedure below; what follows is a summary for this
harness, not a replacement for reading it.

## 2 · The first sweep — every lens, the whole tree, at once

This is v2's one-shot mode: every lens (money/credits, authorization,
secrets and gates, URL/request handling, the data layer, this repo's own
conventions, the evidence tools) reads the **entire tree in one pass**,
before anything gets fixed. A lens that starts fixing has stopped looking.

- If the harness can fan work out to parallel subagents, run the lenses
  concurrently; otherwise run them one after another. Either way, pin every
  lens to the same single checkout of the tree — never mix a stale or
  divergent copy into the sweep.
- **Confirm every finding by reading the actual code before recording
  it.** A pattern that merely looks right is not evidence; open the file,
  trace the value, and only then write the line down.
- Merge all lenses into **one report**, in the checklist's own output
  format: one section per category, each finding as `- **[severity]**
  \`path:line\` — what's wrong. Fix: what to do.` A category with nothing
  in it gets one line saying so.

## 3 · One fix wave

Fix everything the sweep found in a single wave, grouped by area so two
fixes rarely land in the same file. Where they do, keep **both** changes —
never let one silently overwrite the other.

**Each area ships its guard before its fixes.** A guard is whatever makes a
new instance of that class of bug loud by default — a test, a lint rule, a
walker over the source. Write it first; it turns the rest of that area's
fixes into a checklist the guard itself can verify.

## 4 · Converge — over the diff, not the codebase

Run every lens again, this time only over what the fix wave changed. Fixes
hide their own defects — a rewrite that drops a check the old code
happened to do, a diagnostic one filter away from deleting real data — and
none of those show up by re-reading the original file.

**Stop at two consecutive clean passes that dug** — re-traced the money and
auth paths, re-ran the evidence tools, and still found nothing new. A quick
pass that finds nothing is shallow, not clean; it doesn't count. If findings
keep landing in one category instead of shrinking, that's a class, not an
instance — stop patching one at a time, sweep the whole class with a guard,
then run the loop again to confirm it actually cleared.

## 5 · Say honestly how it stopped

Exactly one of three endings, and say which:

- **Converged** — two consecutive clean passes that dug.
- **Flagged systemic** — findings kept landing in one category, so a class
  sweep closed it instead of a patch of each instance.
- **Capped** — a pass budget, a time box, or the developer's own call ended
  it first. A capped run is a real result; never describe it as converged.

## 6 · Only with a plain yes: tell nittim the counts

Nothing so far has sent anything anywhere. This last step is optional, is
the developer's decision alone, and only happens if they say yes in plain
words to something like: *"Share anonymised counts of this loop with
nittim — integers only, never code, paths or titles?"*

If they say yes, call the `report_loop` MCP tool (or, without MCP, `POST
https://nittim.com/api/v1/loop/report` with a key from
https://nittim.com/keys):

- `repo_hash` — a sha256 **you** compute over the repo's canonical identity
  (e.g. lowercased `owner/repo`); never send the name itself.
- `repo_size_bucket` — xs/s/m/l/xl.
- `passes` — one entry per pass actually run, in order, each with its
  category → severity counts, how many findings it fixed, and whether it
  was clean. The one-shot sweep in step 2 is pass 1, covering every lens at
  once; each convergence round in step 4 is a later pass.
- `convergence` and `swept` if you know them.

Never a title, a file path, or a snippet — the schema has no field for
one, so there's nothing to over-share even by accident. This call carries
no cost either way; it is data consent, not spend consent.

Everything above, steps 1–5, is the whole review. Posting the counts is a
courtesy back to nittim, never a requirement for finishing it.
