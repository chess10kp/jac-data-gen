"""Guess the name of the game from the --clone argument."""
def guess_game_name_from_clone_arg(clone_arg: str) -> str {
    if "/" in clone_arg {
        last_value = clone_arg.split("/")[-1];
        return last_value.split('.')[0];
    }
    return clone_arg;
}