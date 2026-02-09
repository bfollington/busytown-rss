# busytown-rss

A personal RSS digest pipeline built on [busytown](https://github.com/gordonbrander/busytown). Three agents fetch feeds, summarize entries, and compile a daily digest — all coordinated through events, all output as markdown on disk.

## How it works

```
trigger.sh
  └─ pushes N × feeds.check events (one per URL in feeds.json)

scanner sees feeds.check → claims it → curls feed → writes entries/*.md → pushes entry.created per entry
summarizer sees entry.created → reads one entry, writes one summary → pushes entry.summarized
digest sees digest.request → reads all summaries → writes digests/YYYY-MM-DD.md
```

Agents communicate only through events and the filesystem. The scanner writes entry files, the summarizer reads them and writes summary files, and the digest agent compiles summaries into a single daily markdown file.

Entries are deduplicated by filename — if `entries/<feed>/<slug>.md` already exists, the scanner skips it. This means re-running the pipeline only processes new posts.

## Setup

```bash
# 1. Install busytown CLI (one-time)
cd busytown && deno task install

# 2. Start the runner
cd busytown-rss
busytown run --agents-dir agents/

# 3. In another terminal, trigger feeds
cd busytown-rss
./trigger.sh

# 4. After scanners and summarizers finish, trigger the digest
busytown events push --worker cron --type digest.request

# 5. Read the digest
cat digests/$(date +%Y-%m-%d).md
```

Watch progress with `tail -f logs/*.log` or `busytown events list --tail`.

## Files

| File | Purpose |
|------|---------|
| `feeds.json` | List of RSS/Atom feed URLs to fetch |
| `trigger.sh` | Pushes `feeds.check` events for each feed (pass `--digest` to also request a digest) |
| `agents/scanner.md` | Fetches feeds, writes raw entries to `entries/` |
| `agents/summarizer.md` | Writes 2-3 sentence summaries to `summaries/` |
| `agents/digest.md` | Compiles summaries into `digests/YYYY-MM-DD.md` |

## Adding feeds

Edit `feeds.json` and run `./trigger.sh` again. Only new entries get written.
