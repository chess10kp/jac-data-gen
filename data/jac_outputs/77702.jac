"""Get 99 percentile sequence length."""
def get_perc_99_len(input_length: Any) -> object {
    lengths = sorted(input_length);
    perc_99 = (len(input_length) * 99) // 100;
    perc_99_len = lengths[perc_99];
    return perc_99_len;
}