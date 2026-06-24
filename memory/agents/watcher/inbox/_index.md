# watcher/inbox — pending proposals

Gated growth proposals the Watcher has written but the user hasn't decided yet. One file per proposal
(`<YYYY-MM-DD>_<slug>.md`, `memory_type: episodic`, `status: pending`). The SessionStart recall hook
counts these and surfaces "N proposals waiting"; `/watch-review` walks them through the four-door gate
(approve · modify · reject · snooze). **Nothing here mutates the OS until the user approves it in-loop.**
