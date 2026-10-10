"""Hackathon judging panel: public API.

Teams enter one track; judges are assigned to tracks and score teams there on
impact, craft and demo (1-10 each).
"""

import from panel { register_team, add_judge, assign, score, team_score, leaderboard, pending }
