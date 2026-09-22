glob REC2020_A = 1.0993;
glob REC2020_B = 0.0181;
glob REC2020_D = 4.5;
glob REC2020_G = 1.0 / 0.45;

"""The Rec.2020 12-bit transfer function."""
def transfer_function_Rec2020_12bit_to_linear(v: float) -> float {
    if v < REC2020_B * REC2020_D {
        return v / REC2020_D;
    }
    return pow((v + (REC2020_A - 1)) / REC2020_A, REC2020_G);
}