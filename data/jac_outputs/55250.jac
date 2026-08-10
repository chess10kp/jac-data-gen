"""formats the values of the record as comma separated values  """
def _format_csv(record: dict[str, object]) -> str {
    ','.join([str(val) for val in record.values()])
}