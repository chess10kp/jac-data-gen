"""Extracts the git revision from the prerelease identifier.

This is assumed to be the last `.` separated component.
"""
def _extract_git_revision(prerelease: str) -> str {
    prerelease.split(".")[-1]
}