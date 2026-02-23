# Workflow

## Creating a Project

```bash
cd cursor-memory
bin/create_project.sh my-project
```

This creates the project folder structure and adds it to `PROJECTS/_index.md`.

## Creating a Topic

```bash
bin/create_topic.sh my-project alert-routing
```

This creates the topic folder with starter files and sets it as the active topic.

## Setting Active Project and Topic

```bash
bin/set_active_project.sh my-project
bin/set_active_topic.sh alert-routing
```

These commands update `ACTIVE_PROJECT.md` and the project's `ACTIVE_TOPIC.md` respectively.

## Automatic Mode (Recommended)

Cursor will auto-manage projects and topics for you via the `cursor-memory-auto` rule:

- **Just start talking.** If you mention a project or topic that doesn't exist, Cursor creates it and sets it as active.
- **Topic drift detected.** If the conversation shifts to a different concern, Cursor will suggest creating or switching to a new topic.
- **End of session.** Say "summarize" or "save memory" and Cursor updates all topic files.

You can also be explicit:
> "Create a new topic called api-migration for the my-project project."

The scripts (`bin/create_project.sh`, `bin/create_topic.sh`, etc.) are still available for manual use or automation outside Cursor.

## Loading Topic Memory in Cursor

When starting a Cursor session, load the relevant context:

1. Open the topic's `overview.md` — this has scope, status, and where you left off.
2. Optionally open `decisions.md` and `open-questions.md` for deeper context.
3. Reference these files using `@` mentions in Cursor chat.

**Example prompt:**
> "Read @overview.md and @decisions.md for the alert-routing topic. Continue where we left off."

## End-of-Session Routine

At the end of every working session, tell Cursor:

> "Summarize and update topic memory."

This should:
1. Update `overview.md` with current status and where you left off.
2. Record any new decisions in `decisions.md`.
3. Update `open-questions.md` — add new questions, close resolved ones.
4. Add a timeline entry in `design-evolution.md` if the design changed.
5. Optionally create a conversation summary in `conversations/YYYY-MM-DD-<slug>.md`.

## Inbox Triage

The `INBOX/00-capture.md` file is a scratchpad for quick notes that don't yet belong to a project.

**Triage weekly:**
- Move items to the appropriate project/topic.
- Create new projects or topics as needed.
- Delete items that are no longer relevant.
