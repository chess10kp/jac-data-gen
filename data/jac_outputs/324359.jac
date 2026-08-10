"""Generate harmonies for as many streams as needed. Obviously limited by range of reasonable frequencies. Used during weights sonification."""
def gen_harmonies(
    n_streams: int, base_freq: int = 200, ratio: list[int] = [1, 4, 5, 6]
) -> list[float] {
    mul_base = 1;
    n_ratio = len(ratio) - 1;
    all_harms = [];
    for stream in range(n_streams + 1) {
        if stream % n_ratio == 0 {
            freq = base_freq * mul_base;
            mul_base += 1;
            harms = [(freq * ratio[i]) / ratio[1] for i in range(1, len(ratio))];
            all_harms += harms;
        }
    }
    return all_harms[:n_streams];
}