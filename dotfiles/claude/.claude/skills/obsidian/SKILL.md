---
name: obsidian
description: Query, read, create, edit, move, or rename notes in the user's Obsidian vault through the deepspace9 MCP gateway (qmd_* search tools and notes_* filesystem tools). Use whenever the user asks about anything that might be in their notes (people, projects, travel, books, games, ideas, plans), wants to add or update a note, or asks where something lives in their vault.
---

# Obsidian vault via deepspace9

The user's Obsidian vault (and other personal sources) is reachable through the **deepspace9** MCP gateway. Two tool families cover the same vault:

- `qmd_*`: search and retrieval over an index of the notes (`qmd_query`, `qmd_get`, `qmd_multi_get`, `qmd_status`).
- `notes_*`: direct filesystem access to the vault at `/vault` (read, write, edit, move, list, search filenames).

In Claude Code these appear as `mcp__deepspace9__<tool>` (or `mcp__claude_ai_DeepSpace9__<tool>` via the claude.ai connector). They are usually deferred: load the ones you need in one `ToolSearch` call, e.g. `select:mcp__deepspace9__qmd_query,mcp__deepspace9__qmd_get,mcp__deepspace9__qmd_multi_get`.

If the `notes_*` tools are missing, run `gateway_status` to see which backends are connected. Without the notes backend the vault is read-only: answer from QMD, and tell the user the notes backend isn't connected rather than attempting edits another way. Never edit the vault through the local filesystem as a substitute.

Paths map 1:1: `qmd://notes/Travel/Japan.md` is `/vault/Travel/Japan.md`.

## Orientation

`/vault/INDEX.md` is the map of the vault: what each top-level folder and notable subfolder contains. Read it (`qmd_get` on `qmd://notes/INDEX.md`) when you need to know where something lives or where a new note belongs, rather than listing directories.

## Finding things

Use QMD as the default way to discover notes. Don't walk or enumerate the vault to find information QMD can retrieve.

`qmd_query` takes typed sub-queries. Usually send two or three:
- `lex`: keywords and exact names (people, projects, products, titles)
- `vec`: a natural-language phrasing of what the user is asking for
- `hyde`: optionally, a sentence or two that would appear in the ideal note

The first sub-query gets double weight, so put the strongest one first.

**Always pass `rerank: false`.** Reranking runs on CPU on the user's server and takes 15–20 seconds per query; unreranked results take about 2 seconds and are usually good enough. Re-run with `rerank: true` only when the first results are clearly off and the question matters. Use `limit` to control result count (default 10).

Then open the hits with `qmd_get` (accepts `qmd://` paths or `#docid`; supports `fromLine`/`maxLines` for long notes) or `qmd_multi_get` for several at once. Search results include context lines describing the folder a hit came from — use them to judge relevance.

Use `notes_*` reads when you already know the exact file, when you need the exact current bytes before editing, or for non-Markdown files.

The QMD index trails file changes by roughly 10–30 seconds and only covers `*.md` (excluding `templates/`). For something just written, read it with `notes_read_text_file`.

## Editing

Treat `/vault` as an Obsidian vault, not an arbitrary directory. It is synced to the user's other devices.

For existing files, use `notes_edit_file`, not `notes_write_file`. Never replace an entire existing note when a localized edit is possible. Before editing:

1. Read the current note with `notes_read_text_file`. Don't use `qmd_get` output for this: it adds line numbers and may be slightly stale.
2. Call `notes_edit_file` with `dryRun: true`.
3. Check that the diff changes only the intended content.
4. Repeat the same edit with `dryRun: false`.
5. Re-read the affected section to verify.

Don't reformat or rewrite unrelated parts of a note.

## Obsidian syntax

Preserve existing YAML frontmatter (keys and their order), `[[wikilinks]]`, `[[wikilinks|aliases]]`, `![[embeds]]`, `#tags`, `^block-ids`, callouts, Markdown links, headings, code fences, and meaningful whitespace.

Never modify anything under `.obsidian/` unless the user explicitly asks.

## Vault conventions

- Use `[[Note Name]]` wikilinks to link notes, matching the surrounding style.
- `people/`: one note per person, named by full name (`people/Luke Peterson.md`), linked as `[[Full Name]]`. Follow the section structure described in `people/people.md`: relationship to the user, how they met, who else they know, things the user is waiting on from them, things they're waiting on from the user, personal facts, and bulleted notes. Check whether a person's note exists before creating one.
- `templates/` holds Obsidian templates (book, game, glossary entry, app, programming language, plugin, Blender page, daily/weekly notes, fleeting note). When creating a note of one of those kinds, read and follow the matching template (via `notes_*`, since `templates/` isn't indexed by QMD).
- `Inbox/` is for notes whose home isn't clear.
- If you add a new top-level folder, or a subfolder worth knowing about, update `INDEX.md` to describe it.
- Never write absolute server paths (`/vault/...`) into note contents.

## Renames and moves

Renaming or moving a note can break links. The filesystem tools can't search file contents, so find references with QMD:

1. Identify the note's current path and basename.
2. Search inbound references: `qmd_query` with a `lex` sub-query for the old basename, `rerank: false`, and a generous `limit`. Confirm each candidate by reading it and looking for `[[Old Name]]`, `[[Old Name|`, `![[Old Name]]`, and Markdown links to the old path. Also check `notes_search_files` for other files with the same basename.
3. If the basename is ambiguous, or several notes could match the same wikilink, explain the ambiguity and don't guess.
4. Make the move with `notes_move_file` and update every affected reference using the editing procedure above.
5. Verify that no stale references remain.

No bulk renames, moves, or deletes unless the user explicitly asks.

## Deletion

The tools can't delete files, which is intentional. Prefer keeping information. If something should be deleted, tell the user which file and why, and they'll do it. Don't empty a note as a substitute for deleting it.

## Concurrency

The vault can change at any time through Obsidian Sync from the user's other devices. If a file differs from what you last read, re-read it and build a new edit rather than forcing the old one.

## After writes

Don't try to trigger syncing or re-indexing. Obsidian Sync and the QMD indexer both watch the filesystem and pick up changes automatically. Never touch QMD's index files.
