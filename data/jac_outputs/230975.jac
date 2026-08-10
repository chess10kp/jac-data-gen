"""Returns the job string used in `generate_job_indexes`."""
def _get_job_string(
    ii: int, jj: int, ii_zfill: int, jj_zfill: int, protocol: int
) -> str {
    s_ii = str(ii).zfill(ii_zfill);
    s_jj = str(jj).zfill(jj_zfill);
    return "p%s-%s-%s" % (str(protocol), s_ii, s_jj);
}