"""analytics.analyze: declaration separated from its impl body."""

import os;

obj AnalyticsReport {
    has pid: int,
        score: float,
        service: str = "analytics";
}

def analyze(signatures: int) -> AnalyticsReport;

impl analyze {
    return AnalyticsReport(pid=os.getpid(), score=float(signatures) * 1.5);
}

with entry {
    for n in [0, 1, 2, 4, 10] {
        r = analyze(n);
        print(str(r.score) + " " + r.service);
    }
}
