glob VALID_SCALINGPOLICYUPDATEBEHAVIOR = (
    "KeepExternalPolicies",
    "ReplaceExternalPolicies"
);

"""
Validate ScalingPolicyUpdateBehavior for ScalingInstruction
Property: ScalingInstruction.ScalingPolicyUpdateBehavior
"""
def validate_scalingpolicyupdatebehavior(scalingpolicyupdatebehavior: str) -> str {
    if scalingpolicyupdatebehavior not in VALID_SCALINGPOLICYUPDATEBEHAVIOR {
        raise ValueError(
            "ScalingInstruction ScalingPolicyUpdateBehavior must be one of: %s"
            % ", ".join(VALID_SCALINGPOLICYUPDATEBEHAVIOR)
        );
    }
    return scalingpolicyupdatebehavior;
}