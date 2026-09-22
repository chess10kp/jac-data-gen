"""Helper to extract EC2 error code from exception.

    For other than EC2 exceptions (those without ec2_code attribute),
    use exception name.
    """
def exception_to_ec2code(ex: object) -> str {
    if hasattr(ex, 'ec2_code') {
        code = getattr(ex, 'ec2_code') as str;
    } else {
        code = `type(ex).__name__;
    }
    return code;
}