"""Checks that email is valid Intel email."""
def is_intel_email(email: str) -> str | bool {
    return email and len(email) > 10 and " " not in email and email.lower().endswith("@intel.com");
}