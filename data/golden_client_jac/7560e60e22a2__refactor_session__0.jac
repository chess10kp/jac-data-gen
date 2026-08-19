import os;

obj AnalyticsReport {
    has pid: int, score: float, service: str = "analytics";
}

def analyze(signatures: int) -> AnalyticsReport;

impl analyze {
    return AnalyticsReport(pid=os.getpid(), score=float(signatures) * 1.5);
}
