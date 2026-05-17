# Host UI Checklist Guidance

> **Note:** The primary entry point is `run-council.sh`, not `council.sh`.
> Use `council.sh` only when you need async/pollable job execution in a host agent UI.
>
> ```bash
> bash scripts/run-council.sh --council tech|career|business|personal "question"
> ```

## When to use council.sh directly

Only when a host agent UI supports native checklist updates and you need
to poll progress incrementally in Codex CLI environments.

## Checklist flow

1. Run `council.sh start "question"` to get a JOB_DIR immediately.
2. Run `council.sh wait JOB_DIR` once to seed the cursor and get the JSON payload.
3. Update the host's native checklist UI using the payload (if provided).
4. Repeat `wait` until progress changes, then update the UI again.
5. Finish with `results` and `clean`.

## Behavior notes

- Do not run a blocking wait before the first checklist update, or the Plan UI may not appear.
- Keep exactly one in_progress item while work remains.
- Preserve existing checklist items and append the [Council] section.
- Avoid a long while loop in a single tool call; update after each wait return.
- Use `--bucket 1` for per-member updates when needed.
