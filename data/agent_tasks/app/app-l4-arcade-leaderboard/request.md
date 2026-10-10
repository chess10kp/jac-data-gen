Building a retro arcade cabinet for a friend's bar. I need a high score service in Jac (project is scaffolded as a service already).

Single endpoint please: `walker:pub submit_score` → `POST /walker/submit_score`, fields `game: str`, `player: str`, `score: int`.

Behavior:
- keep only each player's best score per game (a lower score than their best is ignored, but still returns the board)
- player initials are stored upper-case, max 3 characters (truncate longer names)
- scores must be ≥ 0; a negative score reports `{"error": "invalid score"}` and changes nothing
- the report is that game's top 5 as a list, best first, each entry `{"player": "ABC", "score": 123}`; ties are ordered by who got the score first

Different games have separate boards. Persist on the graph under root. Write some tests as well.
