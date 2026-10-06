"""Patient node — central hub of the AgeWise graph.

Every piece of data (claims, documents, legal docs, finances) connects
through the patient node. Represents an elderly person receiving care.
"""

node Patient {
    has name: str,
        dob: str = "",              # ISO date YYYY-MM-DD
        medicare_id: str = "",      # Medicare Beneficiary Identifier (MBI)
        medicaid_id: str = "",      # Medicaid ID (state-specific)
        address: str = "",
        city: str = "",
        state: str = "",
        zip_code: str = "",
        phone: str = "",
        email: str = "",
        emergency_contact_name: str = "",
        emergency_contact_phone: str = "",
        primary_language: str = "English",
        created_at: str = "",
        updated_at: str = "";
}
