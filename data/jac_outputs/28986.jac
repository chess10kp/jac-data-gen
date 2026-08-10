"""Test lifecycle parser."""
def group_instance_count_json(`obj: dict[str, list[dict[str, list[dict[str, str]]]]]) -> int {
    if not `obj['AutoScalingGroups'] {
        return 0;
    }
    instances = `obj['AutoScalingGroups'][0]['Instances'];
    in_service = 0;
    for instance in instances {
        if instance['LifecycleState'] == 'InService' {
            in_service += 1;
        }
    }
    return in_service;
}