"""Insurer node — insurance company or Medicare Administrative Contractor.

payer_id is the standard identifier used on claims (CMS-1500 Box 11c).
"""

node Insurer {
    has payer_id: str = "",
        name: str = "",
        plan_types: list[str] = [],
        # MEDICARE_ORIGINAL | MEDICARE_ADVANTAGE | MEDIGAP | PART_D | MEDICAID
        claims_address: str = "",
        claims_phone: str = "",
        prior_auth_phone: str = "",
        appeals_address: str = "",
        appeals_fax: str = "",
        mac_jurisdiction: str = "",     # Medicare Administrative Contractor
        website: str = "";
}
