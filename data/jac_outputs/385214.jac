""" Generate a managed instance group resource. """
def get_managed_instance_group(
    project_id: Any,
    name: Any,
    healthcheck: Any,
    instance_template_name: Any,
    base_instance_name: Any,
    zone: Any
) -> object {
    resource = {
        'name': name,
        'type': 'gcp-types/compute-v1:instanceGroupManagers',
        'properties': {
            'project': project_id,
            'instanceTemplate': ('$(ref.' + instance_template_name + '.selfLink)'),
            'baseInstanceName': base_instance_name,
            'zone': zone,
            'targetSize': 1,
            'autoHealingPolicies': [
                {
                    'healthCheck': ('$(ref.' + healthcheck + '.selfLink)'),
                    'initialDelaySec': 120
                }
            ]
        }
    };
    return resource;
}