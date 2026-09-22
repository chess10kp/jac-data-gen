"""Create test fixture absolute copy number variation"""
def genomic_del5_abs_37(genomic_del5_37_loc: dict[str, str | int]) -> dict[str, str | dict[str, str | int]] {
    return {
        "type": "AbsoluteCopyNumber",
        "_id": "ga4gh:VAC.9zhlg8DRSsE87N5SngYrMDWXStzp_WOX",
        "subject": genomic_del5_37_loc,
        "copies": {"type": "Number", "value": 2}
    };
}