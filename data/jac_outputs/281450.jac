"""Initialize stats related to changes in the bugfix commit."""
def init_bugfix_changes_stats(
    stats: dict,
    data: dict,
    commit: str,
    changes: dict
) -> dict {
    if commit not in stats {
        stats[commit] = {};
    }
    stats[commit].update({
        'n_changes': len(changes),
        'n_effective': len([pair for (pair, status) in changes.items() if status != 'D']),
        'n_renames': len([pair for (pair, status) in changes.items() if status == 'R']),
        'n_deletions': len([pair for (pair, status) in changes.items() if status == 'D']),
        'n_additions': len([pair for (pair, status) in changes.items() if status == 'A'])
    });
    return stats;
}