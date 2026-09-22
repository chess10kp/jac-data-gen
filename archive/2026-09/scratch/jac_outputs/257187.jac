"""Add sqlalchemy conversion helper info

    Convert aggregation -> _aggregation_fn,
    as -> _cast_to_datatype and
    default -> _coalesce_to_value"""
def _field_post(field: dict[str, object]) -> dict[str, object] {
    if "as" in field {
        field["_cast_to_datatype"] = field.pop("as");
    }
    if "default" in field {
        field["_coalesce_to_value"] = field.pop("default");
    }
    return field;
}