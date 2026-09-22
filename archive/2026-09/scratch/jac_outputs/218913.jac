"""
    Get the minimum items required for re-installing a (list of) tools
    """
def get_repo_from_tool(tool: Any) -> object {
    if not tool.get('tool_shed_repository', None) {
        return {};
    }
    tsr = tool['tool_shed_repository'];
    repo = {
        'name': tsr['name'],
        'owner': tsr['owner'],
        'tool_shed_url': tsr['tool_shed'],
        'revisions': [tsr['changeset_revision']],
        'tool_panel_section_id': tool['panel_section_id'],
        'tool_panel_section_label': tool['panel_section_name']
    };
    return repo;
}