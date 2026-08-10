"""Create compression options for ZFP in expert mode."""
def zfp_expert_opts(minbits: int, maxbits: int, maxprec: int, minexp: int) -> tuple[int, int, int, int, int, int] {
    zfp_mode_expert = 4;
    return (zfp_mode_expert, 0, minbits, maxbits, maxprec, minexp);
}