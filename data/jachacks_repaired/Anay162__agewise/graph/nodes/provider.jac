"""Provider node — a healthcare provider who submits claims.

NPI is the unique identifier. taxonomy_code identifies the specialty.
"""

node Provider {
    has npi: str = "",                  # 10-digit NPI
        name: str = "",
        taxonomy_code: str = "",        # provider specialty taxonomy
        specialty: str = "",
        address: str = "",
        city: str = "",
        state: str = "",
        zip_code: str = "",
        phone: str = "",
        fax: str = "",
        billing_name: str = "",         # may differ from practice name
        group_npi: str = "",            # group/organization NPI
        accepts_medicare: bool = True,
        is_participating: bool = True;  # Medicare participating provider
}
