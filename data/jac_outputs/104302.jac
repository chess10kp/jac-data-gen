"""Initialize returns list. Each state has four possible actions."""
def returns_lists(cells: int = 16, actions: int = 4) -> dict[str, list[object]] {
    def create_array(n: int, lst: list[str]) -> list[str] {
        for i in range(n) {
            lst.append(str(i));
        }
        return lst;
    }
    possible_states = [];
    possible_states = create_array(cells, possible_states);
    possible_actions = [];
    possible_actions = create_array(actions, possible_actions);
    returns = {};
    for state in possible_states {
        for action in possible_actions {
            returns[(state + ", " + action)] = [];
        }
    }
    return returns;
}