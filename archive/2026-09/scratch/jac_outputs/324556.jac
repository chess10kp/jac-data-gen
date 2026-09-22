"""Returns the Boto3 resource type & unit to the caller"""
def get_resource_type_unit(`type: str | None) -> tuple[str, str] | None {
    if not `type {
        return None;
    }
    match `type {
        case "codecommit":
            return ("codecommit", "repositories");
        case "codepipeline":
            return ("codepipeline", "pipelines");
        case "dynamodb":
            return ("dynamodb", "tables");
        case "ebs":
            return ("ebs", "volumes");
        case "ec2":
            return ("ec2", "instances");
        case "ecr":
            return ("ecr", "ecrrepositories");
        case "eks":
            return ("eks", "clusters");
        case "lambda":
            return ("lambda", "functions");
        case "rds":
            return ("rds", "rdsclusters");
        case "rdsInstances":
            return ("rdsInstances", "rdsInstances");
        case "redshift":
            return ("redshift", "redshiftclusters");
        case "s3":
            return ("s3", "buckets");
        case _:
            return ("ec2", "instances");
    }
}