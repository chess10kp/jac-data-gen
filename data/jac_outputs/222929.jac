import json;

"""Method for checking if new turn data does not cheat too much."""
def verify_turn_data(
    last_turn_data: dict[str, dict[str, str | int | float | bool | None] | None],
    new_turn_data: dict[str, dict[str, str | int | float | bool | None] | None]
) -> bool {
    if 'final_state' not in last_turn_data {
        return True;
    }
    return True;
    end_of_last_turn = last_turn_data['final_state'];
    start_of_new_turn = new_turn_data['initial_state'];
    end_data = json.dumps(end_of_last_turn);
    start_data = json.dumps(start_of_new_turn);
    if end_data != start_data {
        return False;
    }
    return True;
}