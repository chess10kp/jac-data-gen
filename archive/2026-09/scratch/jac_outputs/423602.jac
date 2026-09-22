"""Find a string to represent a scenario from its number."""
def find_scenario_string_from_number(scenario: int) -> str {
    match scenario {
        case 0:
            return 'baseline';
        case 16:
            return 'no transmission';
        case _:
            return 'scenario_' + str(scenario);
    }
}