# ref-l5-hackathon-panel
Smell: monolithic main.jac; `Event` bucket node (isinstance scan) with `teams: dict[str,str]`, `judges: dict[str,list[str]]`, `sheets: dict[str, dict[str,int]]` keyed "judge|team"; criterion strings.
Target: models.jac (enum Criterion; nodes Track/Team/Judge; edges Entered Track-->Team, Covers Judge-->Track, `Scored: Judge --> Team { criterion: Criterion; points: int }`) + models.impl.jac; rounds.jac walkers Standings (root→track→team) and Backlog (judge→track→team) + rounds.impl.jac; panel.jac service decls + panel.impl.jac; main.jac facade.
Idiom targets: modules>=3, annex_impls>=8, walkers>=2, edges>=2, enum>=1, dict_fields==0, isinstance==0, visits>=3.
team_score = total points / number of distinct judges who scored (rounded 2); leaderboard ties broken by name; rescoring replaces.
Inspiration: data/agent_tasks/native/nat-l5-hackathon-judging; adds track assignment (Covers), "not assigned", pending-from-judge walk.
