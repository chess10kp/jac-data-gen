"""Calculate the maximum symmetric quantized value according to number of bits"""
def calc_max_quant_value(bits: Any) -> object {
    return ((2 ** (bits - 1)) - 1);
}