"""Map devlink trap group names into unified Mellanox WJH drop types."""
def get_drop_type(group_name: str) -> str {
    group_name.split("_")[0]
}