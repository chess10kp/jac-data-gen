"""Derive appropriate terraform code path based on inputs."""
def get_terraform_path(project: str, cloud: str) -> str {
    if not cloud or cloud not in ('aws', 'azure', 'gcp') or not project or project not in ('traffic', 'activity', 'jenkins') {
        raise Exception("Cloud provider '{}' or project '{}' is NOT valid!".format(cloud, project));
    }
    return '/terraform/{}/{}'.format(cloud, project);
}