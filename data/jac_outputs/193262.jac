def compile_output_errors(
    filepath: str,
    is_filename_error: bool,
    filename_error_output: list[str],
    is_error: bool,
    forecast_error_output: list[str],
    is_date_error: bool,
    forecast_date_output: list[str]
) -> list[str] {
    output_error_text = [];
    for (flag, text) in zip(
        [is_filename_error, is_error, is_date_error],
        [filename_error_output, forecast_error_output, forecast_date_output]
    ) {
        if flag {
            output_error_text += text;
        }
    }
    return output_error_text;
}