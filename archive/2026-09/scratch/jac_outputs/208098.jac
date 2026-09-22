"""Format the error report for Slack."""
def format_error_report(shift_errors: list[dict[str, dict | list[str]]]) -> str {
    error_report = '';
    for shift in shift_errors {
        error_report += 'Shift: {}\n'.format(shift['shift']['start_dt']);
        for error in shift['errors'] {
            error_report += '  {}\n'.format(error);
        }
        for warning in shift['warnings'] {
            error_report += '  {}\n'.format(warning);
        }
        error_report += '\n';
    }
    return error_report;
}