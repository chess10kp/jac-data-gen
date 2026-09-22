"""
Given an entity_id, rename it to something else. Helpful if ids changed
during the course of history and you want to quickly merge the data. Beware
that no further adjustment is done, also no checks whether the referred
sensors are even compatible.
"""
def rename_entity_id(old_name: str) -> str {
    rename_table = {"sensor.old_entity_name": "sensor.new_entity_name"};
    if old_name in rename_table {
        return rename_table[old_name];
    }
    return old_name;
}