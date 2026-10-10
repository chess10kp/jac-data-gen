"""
Healthcare fraud graph schema.

Nodes: Provider, Patient, Claim, Physician
Edges: untyped (++>) with direction encoding semantics:
  root       --> Provider   (registered providers)
  Provider   --> Claim      (claims billed by provider)
  Patient    --> Claim      (claims filed by patient)
  Claim      --> Physician  (attending physician on claim)
"""

node Provider {
    has id: str,
        fraud_label: str,          # "Yes" / "No"
        total_claims: int = 0,
        total_amount: float = 0.0,
        inpatient_count: int = 0,
        outpatient_count: int = 0;
}

node Patient {
    has id: str,
        gender: int = 0,           # 1=M  2=F  0=unknown
        state: int = 0,
        age: int = 0,
        chronic_conditions: list[str] = [],
        deceased: bool = False,
        ip_annual_reimbursed: float = 0.0,
        op_annual_reimbursed: float = 0.0;
}

node Claim {
    has id: str,
        amount: float = 0.0,
        claim_type: str = "",      # "inpatient" / "outpatient"
        claim_start: str = "",
        claim_end: str = "",
        los_days: int = 0,
        diagnosis_codes: list[str] = [],
        procedure_codes: list[str] = [],
        provider_id: str = "",     # denormalized for fast access in walkers
        bene_id: str = "";
}

node Physician {
    has id: str;
}
