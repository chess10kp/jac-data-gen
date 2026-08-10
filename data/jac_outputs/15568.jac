"""
    Parse the output of ``SESConnection.list_verified_emails()`` and get
    a list of emails.
    """
def emails_parse(emails_dict: Any) -> object {
    return sorted([email for email in emails_dict['VerifiedEmailAddresses']]);
}