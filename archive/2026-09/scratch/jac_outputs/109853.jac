"""Default error formatter for _FindNewViolationsOfRule."""
def _ReportFileAndLine(filename: str, line_num: int) -> str {
    return '%s (line %s)' % (filename, line_num);
}