def ip_bytes_to_int(ip_bytes: list[int]) -> int {
    return (ip_bytes[0] << 24) | (ip_bytes[1] << 16) | (ip_bytes[2] << 8) | ip_bytes[3];
}