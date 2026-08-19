def compute_checksum(data_packet: Any) -> object {
    checksum = 0;
    for byte in data_packet {
        checksum += byte;
        if (checksum > 255) {
            checksum -= 255;
        }
    }
    checksum_complement = ~checksum & 255;
    return checksum_complement;
}



with entry {
    print(compute_checksum([1, 2, 3, 4]));
    print(compute_checksum([1, 2, 3]));
    print(compute_checksum([5, 5, 5]));
}
