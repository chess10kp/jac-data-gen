"""
    m07.turn left.....
    return none........
    """
def dev_turn_left(dev0: Any) -> object {
    try {
        dev0.swipe(150, 1000, 850, 1000);
    } except Exception as e {
        print("error at dev_turn_left.");
        ;
    } else {
        ;
    }  finally {
        return None;
    }
}