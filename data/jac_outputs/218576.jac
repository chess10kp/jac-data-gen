"""Return Destroyed Volume or None"""
def get_destroyed_volume(vol: object, array: object) -> bool {
    try {
        return bool(getattr(array, "get_volume")(vol, pending=True)["time_remaining"] != "");
    } except Exception {
        return False;
    }
}