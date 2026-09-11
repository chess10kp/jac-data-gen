"""Saber5656/kotodama#28 — benchmark pipeline dependency closure and memory budgets.

kotodama-bench runs capture → asr → format stages; planners need transitive
prerequisite closure, runnable gates, and §13 RSS budget checks. Hand-rolled
pred adjacency plus deque BFS closure.
"""
import from __future__ { annotations }
import from collections { deque }
"""Mutable bench planner; fresh instance per test."""
class KotodamaBench {
    def init(self: KotodamaBench) -> None {
        self._stages: list[str] = [];
        self._preds: dict[(str, list[str])] = {};
        self._budgets: dict[(str, int)] = {};
    }
    def load(
        self: KotodamaBench,
        stages: list[str],
        deps: list[tuple[(str, str)]],
        budgets: dict[(str, int)]
    ) -> None {
        self._stages = `list(stages);
        self._budgets = `dict(budgets);
        self._preds = {sid: [] for sid in stages};
        for (consumer, upstream) in deps {
            if ((consumer in self._preds) and (upstream in self._preds)) {
                self._preds[consumer].append(upstream);
            }
        }
    }
    def prerequisite_closure(self: KotodamaBench, stage_id: str) -> list[str] {
        if (stage_id not in self._preds) {
            return [];
        }
        seen: set[str] = {stage_id};
        queue: deque[str] = deque(self._preds.get(stage_id, []));
        found: list[str] = [];
        while queue {
            cur = queue.popleft();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            found.append(cur);
            for upstream in self._preds.get(cur, []) {
                if (upstream not in seen) {
                    queue.append(upstream);
                }
            }
        }
        return sorted(found);
    }
    def runnable(self: KotodamaBench, stages_done: set[str]) -> list[str] {
        out: list[str] = [];
        for sid in sorted(self._stages) {
            if (sid in stages_done) {
                continue;
            }
            reqs = self._preds.get(sid, []);
            if all((r in stages_done) for r in reqs) {
                out.append(sid);
            }
        }
        return out;
    }
    def over_budget(self: KotodamaBench, rss: dict[(str, int)]) -> list[str] {
        bad: list[str] = [];
        for sid in sorted(self._stages) {
            if (
                (sid in rss)
                and (sid in self._budgets)
                and (rss[sid] > self._budgets[sid])
            ) {
                bad.append(sid);
            }
        }
        return bad;
    }
}

