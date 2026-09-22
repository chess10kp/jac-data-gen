"""In here you can make the mapping and translation of the different parameter values and attributes for the Incident Software of your desire."""
def get_program_argument(problem_details: dict[str, str | list[str] | list[dict[str, str]]]) -> list[str] {
    nr = problem_details['displayName'];
    status = problem_details['status'];
    severity = problem_details['severityLevel'];
    element = problem_details['impactLevel'];
    tags = problem_details['tagsOfAffectedEntities'];
    msg = "Problem [{0}]: Status={1}, Severity={2}, ImpactLevel={3}, Tags={4}".format(
        nr, status, severity, element, tags
    );
    if 'rankedImpacts' in problem_details {
        elements = problem_details['rankedImpacts'];
    } else {
        elements = problem_details['rankedEvents'];
    }
    arguments_list = [];
    for item in elements {
        e_name = item['entityName'];
        e_severity = item['severityLevel'];
        e_impact = item['impactLevel'];
        e_eventType = item['eventType'];
        element_msg = msg;
        element_msg += " Entity details: Entity={0}, impactLevel={1}, severity={2}, eventType={3}".format(
            e_name, e_severity, e_impact, e_eventType
        );
        arguments_list.append(element_msg);
    }
    return arguments_list;
}