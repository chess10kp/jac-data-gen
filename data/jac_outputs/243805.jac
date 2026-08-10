glob DEVICE_PREFIX = '/job:localhost/replica:0/task:0/device:';

"""/job:localhost/replica:0/task:0/device:CPU:0 -> /cpu:0"""
def _simplify_device_name(device: str) -> str {
    if device.startswith(DEVICE_PREFIX) {
        device = '/' + device[len(DEVICE_PREFIX):];
    }
    return device.lower();
}