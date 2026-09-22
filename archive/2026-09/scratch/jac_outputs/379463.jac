"""Gets proxy column names."""
def get_proxy_column_names(
    protected_columns: list[str], noise_param: float, noise_index: str = ''
) -> list[str] {
    return [
        'PROXY' + noise_index + '_' + ('%0.2f_' % noise_param) + column_name
        for column_name in protected_columns
    ];
}