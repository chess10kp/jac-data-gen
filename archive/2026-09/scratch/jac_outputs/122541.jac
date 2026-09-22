"""See readonly_field_as_table_row().
  """
def readonly_safe_field_as_twoline_table_row(
    field_label: Any, field_value: Any
) -> object {
    return {'field_label': field_label, 'field_value': field_value};
}