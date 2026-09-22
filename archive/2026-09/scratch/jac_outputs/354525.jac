obj VolumeArray {
    def get_volume(vol: str, protocol_endpoint: bool = True, pending: bool = True) -> dict[str, str];
}

"""Return Destroyed Endpoint or None"""
def get_destroyed_endpoint(vol: str, array: VolumeArray) -> bool {
    try {
        return bool(array.get_volume(vol, protocol_endpoint=True, pending=True)["time_remaining"] != "");
    } except Exception {
        return False;
    }
}