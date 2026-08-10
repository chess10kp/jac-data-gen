"""Convert an email address from TC to a STIX pattern."""
def email_address_stix_pattern_producer(data: Any) -> object {
    return f"[email-addr:value = '{data.get('summary')}']";
}