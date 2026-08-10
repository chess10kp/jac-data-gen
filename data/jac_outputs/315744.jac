"""Helper function that makes separate make_params for behavioral data."""
def _prep_behavior(dataset: dict[str, int | float | str | bool], lag: int | None, make_params: dict[str, bool | tuple[int, ...] | int]) -> dict[str, bool | tuple[int, ...] | int] | None {
    if lag is None {
        return None;
    }
    behavior_make_params = make_params.copy();
    behavior_make_params['allow_nans'] = True;
    if 'align_range' in behavior_make_params {
        behavior_make_params['align_range'] = tuple(
            [(t + lag) for t in make_params['align_range']]
        );
    } else {
        behavior_make_params['align_range'] = (lag, lag);
    }
    return behavior_make_params;
}