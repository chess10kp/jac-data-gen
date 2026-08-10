"""Get default filename of a LOFAR station calibration table."""
def _default_caltab_filename(stnid: str, rcumode: str) -> str {
    'CalTable_' + stnid[2:] + '_mode' + rcumode + '.dat'
}