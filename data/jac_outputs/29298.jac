"""Mix two wave body into one."""
def mix_wave(src: list[int], dst: list[int]) -> list[int] {
    if len(src) > len(dst) {
        (dst, src) = (src, dst);
    }
    for (i, sv) in enumerate(src) {
        dv = dst[i];
        if sv < 128 and dv < 128 {
            dst[i] = int(sv * dv / 128);
        } else {
            dst[i] = int(2 * (sv + dv) - sv * dv / 128 - 256);
        }
    }
    return dst;
}