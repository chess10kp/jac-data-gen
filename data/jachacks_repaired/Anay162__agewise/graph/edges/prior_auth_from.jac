"""prior_auth_from edge — PriorAuth request submitted to Insurer."""

edge prior_auth_from {
    has submission_method: str = "",  # FAX | PHONE | PORTAL | EDI
        submission_date: str = "";
}
