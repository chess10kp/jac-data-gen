"""Return human pick/drop actions for the given cube."""
def human_tidy(agents: list[str], self_state: dict[str, str], self_name: str, cube: str) -> list[tuple[str, str] | tuple[str]] {
    return [("human_pick_cube", cube), ("human_drop_cube", )];
}