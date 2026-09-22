"""Creates a dictionary object that can later be saved to a CSV formatted
    file for use in the Gross Range lookup tables."""
def format_gross_range(
    param: str,
    sensor_range: list[float],
    user_range: list[float],
    site: str,
    `node: str,
    sensor: str,
    stream: str,
    source: str
) -> dict[str, object] {
    qc_dict = {
        'subsite': site,
        'node': `node,
        'sensor': sensor,
        'stream': stream,
        'parameter': {'inp': param},
        'qcConfig': {
            'qartod': {
                'gross_range_test': {
                    'suspect_span': [
                        '{}'.format(user_range[0]),
                        '{}'.format(user_range[1])
                    ],
                    'fail_span': [
                        '{}'.format(sensor_range[0]),
                        '{}'.format(sensor_range[1])
                    ]
                }
            }
        },
        'source': source
    };
    return qc_dict;
}