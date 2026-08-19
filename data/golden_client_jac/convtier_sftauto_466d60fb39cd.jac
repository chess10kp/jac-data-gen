def compute_checksum(data_packet: Any) -> object {
    checksum = 0;
    for byte in data_packet {
        checksum += byte;
    }
    checksum = checksum & 255;
    return (~checksum & 255);
}



with entry {
    print(compute_checksum([]));
}
