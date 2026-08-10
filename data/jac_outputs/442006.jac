"""Generate possible Terraform workspace tfvars filenames."""
def gen_workspace_tfvars_files(environment: str, region: str) -> list[str] {
    return [("%s-%s.tfvars" % (environment, region)), ("%s.tfvars" % environment)];
}