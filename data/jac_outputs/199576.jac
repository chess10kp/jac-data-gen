"""
    Finds a particular workflow with the given uuid.
    """
def find_workflow_uuid(galaxy_workflows: list[dict[str, str]], uuid: str) -> dict[str, str] | None {
    workflow = None;
    for w in galaxy_workflows {
        if w['latest_workflow_uuid'] == uuid {
            if workflow != None {
                raise Exception(
                    "Error: multiple workflows with uuid="
                    + uuid
                    + ", please use --workflow-id to specify"
                );
            } else {
                workflow = w;
            }
        }
    }
    return workflow;
}