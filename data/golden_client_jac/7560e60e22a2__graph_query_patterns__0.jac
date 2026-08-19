"""RL driver (pure-lib): analytics.analyze (compute an AnalyticsReport score).

Origin: this_is_jac/analytics.jac (the analyze logic, isolated from any io/time/graph
machinery). Deterministic: the score is float(signatures) * 1.5, an exact multiple of
1.5; only score and service are printed (never the non-deterministic pid), so stdout is
the same fixed lines on every run. The marked body is the unit the policy must
regenerate; the with entry block exercises it on fixed inputs and prints a deterministic
projection.
"""

import os;

obj AnalyticsReport {
    has pid: int,
        score: float,
        service: str = "analytics";
}

def analyze(signatures: int) -> AnalyticsReport {
    # >>>HOLE id="lib_analyze_score" instruction="Return a new AnalyticsReport whose pid field is the current process id (os.getpid()) and whose score field is signatures converted to float and multiplied by 1.5. Leave service at its default."
    return AnalyticsReport(pid=os.getpid(), score=float(signatures) * 1.5);
    # <<<HOLE
}

with entry {
    for n in [0, 1, 2, 4, 10] {
        r = analyze(n);
        print(str(round(r.score, 6)) + " " + r.service);
    }
}
