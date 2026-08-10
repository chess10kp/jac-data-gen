"""Helper function to derive parameter name and units."""
def _get_parameter_metadata(driver: str, band: dict[str, str]) -> dict[str, str | None] {
    parameter: dict[str, str | None] = {
        'id': None,
        'description': None,
        'unit_label': None,
        'unit_symbol': None,
        'observed_property_id': None,
        'observed_property_name': None
    };
    if driver == 'GRIB' {
        parameter['id'] = band['GRIB_ELEMENT'];
        parameter['description'] = band['GRIB_COMMENT'];
        parameter['unit_label'] = band['GRIB_UNIT'];
        parameter['unit_symbol'] = band['GRIB_UNIT'];
        parameter['observed_property_id'] = band['GRIB_SHORT_NAME'];
        parameter['observed_property_name'] = band['GRIB_COMMENT'];
    }
    return parameter;
}