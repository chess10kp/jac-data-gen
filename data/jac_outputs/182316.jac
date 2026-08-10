"""This function makes array of low density strings of size block_size."""
def low_density_generator(block_size: int) -> list[str] {
    resp = [bin(0)[2:].zfill(block_size)];
    for i in range(block_size) {
        if i > 0 {
            for j in range(i) {
                resp.append(bin((1 << i) | (1 << j))[2:].zfill(block_size));
            }
        } else {
            for k in range(block_size) {
                resp.append(bin(1 << k)[2:].zfill(block_size));
            }
        }
    }
    return resp;
}