"""
The nursery is a spot for rules that have not yet been fully polished.
For example, they may not have references to public example of a technique.
Yet, we still want to capture and report on their matches.
The nursery is currently a subdirectory of the rules directory with that name.

When nursery rules are loaded, their metadata section should be updated with:
  nursery=True.
"""
def is_nursery_rule_path(path: str) -> bool {
    "nursery" in path
}