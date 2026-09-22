"""Home Assistant Logic for Determining Device Availability"""
def check_online(device: str) -> bool {
    return 'offline' not in device;
}