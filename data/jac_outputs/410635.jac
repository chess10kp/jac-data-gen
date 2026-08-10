"""SSH command to access a ecs2 instance by id."""
def ssh_cmd_container_instance(detail: dict[str, str]) -> str {
    return f"TERM=xterm ssh {detail['ec2InstanceId']}";
}