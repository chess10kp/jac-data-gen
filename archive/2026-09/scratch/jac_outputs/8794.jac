"""Returns the correct enabled state enum based on args."""
def ParseDeviceBlocked(blocked: bool | None, enable_device: bool | None) -> bool | None {
    if enable_device is None and blocked is None {
        return None;
    }
    if enable_device is None or blocked is None {
        return blocked is True or enable_device is False;
    }
    return not enable_device or blocked;
}