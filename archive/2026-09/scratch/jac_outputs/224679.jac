"""
If there happened to be progress between the two statuses we check if it was valid.
Thus, we return False if there was invalid progress, and True otherwise (even if there was no progress).
Stage change counts as progress, but has to be done in the right order.
Also if both runs are in the same stage, we compare progress.
"""
def has_progressed_validly(
    status_old: dict[str, dict[str, int | dict[str, float]]],
    status_new: dict[str, dict[str, int | dict[str, float]]]
) -> bool {
    old_stage = status_old['current_stage']['number'];
    new_stage = status_new['current_stage']['number'];
    if old_stage < new_stage {
        return True;
    } elif old_stage > new_stage {
        return False;
    }
    if 'progress' in status_old['current_stage'] and 'progress' in status_new['current_stage'] {
        assert 0 <= status_new['current_stage']['progress']['relative'] <= 1.0, "{} not between 0 and 1".format(
            status_new['current_stage']['progress']['relative']
        );
        assert 0 <= status_old['current_stage']['progress']['relative'] <= 1.0, "{} not between 0 and 1".format(
            status_old['current_stage']['progress']['relative']
        );
        if status_new['current_stage']['progress']['relative'] < status_old['current_stage']['progress']['relative'] {
            return False;
        }
        return True;
    }
    return True;
}