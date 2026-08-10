"""Migrate scrum report template of version 1 to version 2."""
def migrate_report_settings_from_1_to_2(data: dict[str, list[str]]) -> dict[str, int | list[str] | dict[str, list[list[str]]]] {
    migrated = dict();
    template_data = data.get("template", []) or [];
    migrated_template = [item.replace("${today}", "${date}") for item in template_data];
    migrated["version"] = 2;
    migrated["questions"] = data.get("questions", []) or [];
    migrated["template"] = {"sections": [migrated_template]};
    return migrated;
}