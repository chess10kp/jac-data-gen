"""Checks whether the build is in progress on buildbot."""
def _IsBuildRunning(build_data: dict[str, dict[str, bool | None] | None]) -> bool {
    current_step = build_data.get('currentStep');
    if current_step and current_step.get('isStarted') and current_step.get('results') is None {
        return True;
    }
    return False;
}