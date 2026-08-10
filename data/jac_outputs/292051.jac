"""Filter to customize WFC3 BIASFILE for hst_gentools/gen_rmap.py.

    Adds precondition_header() hook to rmap header.   Driven by CDBS special case code.
    """
def wfc3_biasfile_filter(kmap: dict[str, str]) -> tuple[dict[str, str], dict[str, dict[str, str]]] {
    header_additions = {
        "hooks": {"precondition_header": "precondition_header_wfc3_biasfile_v1"}
    };
    return (kmap, header_additions);
}