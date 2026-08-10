"""Generates a otpauth:// URI"""
def generate_otp(label: str, user: str, key: str) -> str {
    return "otpauth://totp/%s:%s?secret=%s&issuer=%s" % (label, user, key, label);
}