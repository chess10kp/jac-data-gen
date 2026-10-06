"""Pharmacy node — pharmacy information for prescription tracking."""

node Pharmacy {
    has pharmacy_id: str = "",
        name: str = "",
        ncpdp_id: str = "",
        npi: str = "",
        address: str = "",
        city: str = "",
        state: str = "",
        zip_code: str = "",
        phone: str = "",
        fax: str = "",
        is_mail_order: bool = False,
        is_preferred: bool = False,
        is_preferred_90_day: bool = False,
        hours: str = "",
        notes: str = "";
}
