"""Takes quantdata in a dict and header with quantkeys. Returns dict of quant intensities with missing keys set to NA."""
def get_quant_NAs(quantdata: dict[str, float | int | str], quantheader: list[str]) -> dict[str, float | int | str] {
    out = {};
    for qkey in quantheader {
        out[qkey] = quantdata.get(qkey, 'NA');
    }
    return out;
}