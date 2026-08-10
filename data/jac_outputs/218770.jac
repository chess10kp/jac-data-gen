"""Determines whether a given actor name is one of a given list of targets."""
def matchActor(name: str | None, targets: list[str]) -> bool {
    if len(targets) == 0 {
        return True;
    }
    if name is None {
        return False;
    }
    for actor in targets {
        if name[:len(actor)] == actor {
            return True;
        }
    }
    return False;
}