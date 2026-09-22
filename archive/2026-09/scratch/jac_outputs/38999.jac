"""
Sort and clean up a list of projects.

Removes duplicates and sorts alphabetically, case-insensitively.
"""
def sort_project_list(in_list: list[str]) -> list[str] {
    normalized = [project.replace(" ", "_") for project in in_list];
    unique_projects = list({project.lower(): project for project in normalized}.values());
    return sorted(project.lower() for project in unique_projects);
}