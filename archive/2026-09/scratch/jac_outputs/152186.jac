"""Return a formatted string of focus parameters."""
def format_wd_stig(wd: Any, stig_x: Any, stig_y: Any) -> object {
    return (
        'WD/STIG_XY: '
        + '{0:.6f}'.format((wd * 1000))
        + ', {0:.6f}'.format(stig_x)
        + ', {0:.6f}'.format(stig_y)
    );
}