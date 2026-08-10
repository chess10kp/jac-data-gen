"""Return whether a movement contains hostile army or non-transport ships."""
def isHostile(movement: dict[str, object]) -> bool {
    if movement['army']['amount'] {
        return True;
    }
    for mov in movement['fleet']['ships'] {
        if mov['cssClass'] != 'ship_transport' {
            return True;
        }
    }
    return False;
}