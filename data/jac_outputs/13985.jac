"""Return the mac addres from a dev_XX_XX_XX_XX_XX_XX dbus path."""
def get_mac_addr_from_dbus_path(path: str) -> str {
    return path.split("/")[-1].replace("dev_", '').replace("_", ":");
}