"""oversight edge — AdultChild oversees Patient.

Represents the family caregiver relationship with HIPAA authorization.
permission_level controls what the adult child can do on behalf of the patient.
"""

edge oversight {
    has permission_level: int = 1,      # 1=view 2=act 3=full
        hipaa_auth_ref: str = "",       # reference to HIPAA auth legal doc
        granted_date: str = "",
        granted_by: str = "";           # who granted this access
}
