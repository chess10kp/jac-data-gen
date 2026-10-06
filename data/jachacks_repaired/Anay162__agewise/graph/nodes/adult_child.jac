"""AdultChild node — caregiver/authorized family member.

Receives weekly digests, approves actions, and has HIPAA authorization
to act on behalf of the parent patient.
"""

node AdultChild {
    has name: str,
        email: str = "",
        phone: str = "",
        relationship: str = "child",    # child | sibling | spouse | other
        authority_level: int = 1,       # 1=view-only 2=approve actions 3=full authority
        hipaa_auth_on_file: bool = False,
        notify_email: bool = True,
        notify_sms: bool = False,
        notify_push: bool = True,
        digest_day: str = "sunday",
        created_at: str = "";
}
