"""Constructs an internal representation of the screens info."""
def build_current_state(sway_outputs: list[dict]) -> dict[str, dict] {
    state = dict();
    for out_spec in sway_outputs {
        state[out_spec['name']] = {
            'x': out_spec['rect']['x'],
            'y': out_spec['rect']['y'],
            'w': out_spec['modes'][-1]['width'],
            'h': out_spec['modes'][-1]['height'],
            'active': out_spec['active'],
            'transform': out_spec.get('transform', 'normal')
        };
    }
    return state;
}