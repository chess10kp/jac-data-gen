def analyze(signatures: int) -> AnalyticsReport {
    return AnalyticsReport(pid=os.getpid(), score=signatures * 1.5);
}
