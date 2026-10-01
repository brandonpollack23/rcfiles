---
name: brain
description: Query, read, create, edit, move, or rename notes in the user's Obsidian vault ("brain") on this machine, through the local qmd CLI (`qmd --index brain`) and the synced vault in ~/Obsidian. Use whenever the user mentions their brain, vault, notes, or Obsidian, or asks about anything that might be in their notes (people, projects, travel, books, games, ideas, plans, past decisions), wants to add or update a note, or asks where something lives in their vault. Prefer it over the ds9-brain skill whenever ~/Obsidian exists here.
---

# Obsidian vault on this machine

The user's Obsidian vault is synced to `~/Obsidian` (by Obsidian Headless, `ob`, in the background, or by the desktop app's own Sync) and indexed by a local qmd index named `brain`. `mise run obsidian` and `mise run qmd` in the user's rcfiles repo set this up; the config is `~/.config/qmd/brain.yml`.

- **Search and retrieve** with the qmd CLI, through Bash: `qmd --index brain <command>`. The shell alias `qmd-brain` is the same thing, but aliases aren't loaded in Bash tool calls, so always spell out `qmd --index brain`.
- **Read and edit** files directly in `~/Obsidian` with the Read, Edit and Write tools.

Paths map 1:1: `qmd://notes/Travel/Japan.md` (results append `?index=brain`; drop it) is `~/Obsidian/Travel/Japan.md`.

If `~/Obsidian` is missing, or `qmd --index brain status` fails or shows no files, this machine isn't set up: use the ds9-brain skill (the same vault on the user's server, over MCP) instead, and tell the user `mise run qmd` sets up the local index.

## Orientation

`~/Obsidian/INDEX.md` is the map of the vault: what each top-level folder and notable subfolder contains. Read it when you need to know where something lives or where a new note belongs, rather than listing directories.

## Finding things

Use qmd as the default way to discover notes. Don't walk the vault to find information qmd can retrieve.

```sh
qmd --index brain search "Luke Peterson" -n 10              # BM25 keywords and exact names: instant
qmd --index brain query $'lex: motorcycle Japan\nvec: riding trips around Japan' -n 10   # hybrid
qmd --index brain vsearch "notes about burnout" -n 10       # vector only
```

- `search` is instant; start there for names, titles and exact terms.
- `query` takes a typed query document, one sub-query per line: `lex:` (keywords, exact names; `"quoted phrases"` and `-negation` work), `vec:` (a natural-language phrasing of what the user wants), and optionally `hyde:` (a sentence or two that would appear in the ideal note). The first line gets double weight, so put the strongest first. Write typed lines yourself rather than passing a plain sentence: a plain sentence runs an extra LLM query-expansion step.
- `query` reranks with a local model by default. Add `--no-rerank` when speed matters more than ordering. The first `query` on a machine downloads its models, which can take minutes.
- `--format json` gives `docid`, `score`, `file`, `line`, `title`, `context` and `snippet` per hit; `--format files` gives just the paths. `-n` sets the result count (default 5).
- Each hit's `context` describes the folder it came from; use it to judge relevance.

Open hits with `qmd --index brain get <qmd://path or #docid>` (`get "qmd://notes/x.md:40:30"` reads 30 lines from line 40), or `multi-get` with a comma-separated list or glob for several. Or just Read the file in `~/Obsidian`.

The index trails file changes by about 10–30 seconds (a background watcher re-indexes after notes stop changing) and only covers `*.md`, not `templates/`. For something just written, read the file.

Unlike the server tools, Grep works on the whole vault here: use it for exact-text questions qmd can't answer, like every note linking to `[[Some Note]]`.

## Editing

Treat `~/Obsidian` as an Obsidian vault, not an arbitrary directory. It syncs to the user's other devices and their server.

For existing files, use Edit, not Write. Never rewrite an entire existing note when a localized edit is possible. Read the note right before editing (not from qmd output, which adds line numbers and may be stale), change only the intended content, and re-read the affected section afterwards to verify.

Don't reformat or rewrite unrelated parts of a note.

## Obsidian syntax

Preserve existing YAML frontmatter (keys and their order), `[[wikilinks]]`, `[[wikilinks|aliases]]`, `![[embeds]]`, `#tags`, `^block-ids`, callouts, Markdown links, headings, code fences, and meaningful whitespace.

Never modify anything under `.obsidian/` unless the user explicitly asks.

## Vault conventions

- Use `[[Note Name]]` wikilinks to link notes, matching the surrounding style.
- `people/`: one note per person, named by full name (`people/Luke Peterson.md`), linked as `[[Full Name]]`. Follow the section structure described in `people/people.md`: relationship to the user, how they met, who else they know, things the user is waiting on from them, things they're waiting on from the user, personal facts, and bulleted notes. Check whether a person's note exists before creating one.
- `templates/` holds Obsidian templates (book, game, glossary entry, app, programming language, plugin, Blender page, daily/weekly notes, fleeting note). When creating a note of one of those kinds, read and follow the matching template.
- `Inbox/` is for notes whose home isn't clear.
- If you add a new top-level folder, or a subfolder worth knowing about, update `INDEX.md` to describe it.
- Never write absolute paths (`/Users/...`, `~/Obsidian/...`) into note contents.

## Renames and moves

Renaming or moving a note can break links.

1. Identify the note's current path and basename.
2. Find inbound references with Grep over `~/Obsidian` (`*.md`) for `[[Old Name]]`, `[[Old Name|`, `[[Old Name#`, `![[Old Name]]`, and Markdown links to the old path. Check for other files with the same basename too.
3. If the basename is ambiguous, or several notes could match the same wikilink, explain the ambiguity and don't guess.
4. Move it with `mv` (quote the paths) and update every affected reference using the editing procedure above.
5. Grep again to verify no stale references remain.

No bulk renames, moves, or deletes unless the user explicitly asks.

## Deletion

Don't delete notes. Prefer keeping information. If something should be deleted, tell the user which file and why, and they'll do it. Don't empty a note as a substitute for deleting it.

## Concurrency

The vault can change at any time as sync brings in edits from the user's other devices. If a file differs from what you last read, re-read it and build a new edit rather than forcing the old one.

## After writes

Don't trigger syncing or re-indexing, and don't run `qmd update`, `embed` or `cleanup`: the sync service and the qmd-brain watcher pick changes up from the filesystem. Never touch qmd's index files in `~/.cache/qmd`.
