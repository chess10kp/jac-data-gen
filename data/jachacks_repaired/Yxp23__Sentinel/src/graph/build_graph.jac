"""
Graph builder + test traversal.

Run from anywhere:
  jac run src/graph/build_graph.jac

Builds a development-subset graph:
  root --> Provider --> Claim --> Physician
           Patient  --> Claim

Provider aggregate stats (total_claims, total_amount, etc.) are pre-computed
in Python from ALL claims so they reflect true billing volumes even though
the graph only holds up to 50 sampled claims per provider.

Then runs GraphStats walker to verify traversal works.
"""

# Add project root to sys.path so the Python loader is importable
::py::
import sys, os as _os
_proj_root = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), '..', '..'))
if _proj_root not in sys.path:
    sys.path.insert(0, _proj_root)
sys.setrecursionlimit(10000)
::py::

include schema;

import from src.loader.load_data { load_subset }

# ---------------------------------------------------------------------------
# Test traversal walker — walks root -> Providers -> Claims
# ---------------------------------------------------------------------------

walker GraphStats {
    has n_providers: int = 0,
        n_fraud: int = 0,
        n_claims: int = 0,
        total_amount: float = 0.0;

    can on_root with Root entry {
        visit [-->];
    }

    can on_provider with Provider entry {
        self.n_providers += 1;
        if here.fraud_label == "Yes" {
            self.n_fraud += 1;
        }
        report {
            "provider":     here.id,
            "fraud":        here.fraud_label,
            "total_claims": here.total_claims,
            "total_amount": here.total_amount
        };
        visit [-->];
    }

    can on_claim with Claim entry {
        self.n_claims += 1;
        self.total_amount += here.amount;
        # Don't visit Physicians here — that's the Collusion Agent's job
    }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

with entry {
    # ── 1. Load pre-filtered data from Python ──────────────────────────────
    # 30 providers, up to 50 sampled claims each; provider stats from all claims.
    data = load_subset(provider_limit=30, non_fraud_sample=15);

    providers = data["providers"];
    patients  = data["patients"];
    claims    = data["claims"];

    # ── 2. Index dicts for O(1) edge wiring ────────────────────────────────
    prov_index: dict = {};
    pat_index:  dict = {};
    phys_index: dict = {};

    # ── 3. Provider nodes ───────────────────────────────────────────────────
    for p in providers {
        fl = "Yes";
        if not p["fraud_label"] {
            fl = "No";
        }
        # Stats pre-computed in Python from ALL claims (not just the sampled graph claims)
        tc = p.get("total_claims", 0) or 0;
        ta = p.get("total_amount", 0.0) or 0.0;
        ic = p.get("inpatient_count", 0) or 0;
        oc = p.get("outpatient_count", 0) or 0;
        prov_node = Provider(
            id=p["id"], fraud_label=fl,
            total_claims=tc, total_amount=ta,
            inpatient_count=ic, outpatient_count=oc
        );
        root ++> prov_node;
        prov_index[p["id"]] = prov_node;
    }
    print(f"[graph] Provider nodes: {len(prov_index)}");

    # ── 4. Patient nodes (reached via Claim edges, not from root) ──────────
    for p in patients {
        g = p["gender"];
        gender_int = 0;
        if g == "M" {
            gender_int = 1;
        } elif g == "F" {
            gender_int = 2;
        }

        state_int = 0;
        if p["state"] is not None {
            state_int = p["state"];
        }
        age_int = 0;
        if p["age"] is not None {
            age_int = p["age"];
        }
        ip_amt = 0.0;
        if p["ip_annual_reimbursed"] is not None {
            ip_amt = p["ip_annual_reimbursed"];
        }
        op_amt = 0.0;
        if p["op_annual_reimbursed"] is not None {
            op_amt = p["op_annual_reimbursed"];
        }

        pat_node = Patient(
            id=p["id"],
            gender=gender_int,
            state=state_int,
            age=age_int,
            chronic_conditions=p["chronic_conditions"],
            deceased=p["deceased"],
            ip_annual_reimbursed=ip_amt,
            op_annual_reimbursed=op_amt
        );
        pat_index[p["id"]] = pat_node;
    }
    print(f"[graph] Patient nodes: {len(pat_index)}");

    # ── 5. Claim nodes + all edges ──────────────────────────────────────────
    n_claims_built = 0;
    for c in claims {
        pid = c["provider_id"];
        prov_node = prov_index.get(pid) as Provider;
        if not prov_node {
            continue;
        }

        amt = 0.0;
        if c["amount"] is not None {
            amt = c["amount"];
        }
        start = "";
        if c["claim_start"] is not None {
            start = c["claim_start"];
        }
        end = "";
        if c["claim_end"] is not None {
            end = c["claim_end"];
        }
        los = 0;
        if c["los_days"] is not None {
            los = c["los_days"];
        }

        claim_node = Claim(
            id=c["id"],
            amount=amt,
            claim_type=c["type"],
            claim_start=start,
            claim_end=end,
            los_days=los,
            diagnosis_codes=c["diagnosis_codes"],
            procedure_codes=c["procedure_codes"],
            provider_id=pid,
            bene_id=c["bene_id"]
        );

        # Provider --> Claim (stats already set from Python pre-computation)
        prov_node ++> claim_node;

        # Patient --> Claim
        bene_id = c["bene_id"];
        pat_node = pat_index.get(bene_id) as Patient;
        if pat_node {
            pat_node ++> claim_node;
        }

        # Claim --> Physician (attending only; others stored as strings on Claim)
        phys_id = c["attending_physician"];
        if phys_id {
            if phys_id not in phys_index {
                phys_node = Physician(id=phys_id);
                phys_index[phys_id] = phys_node;
            }
            claim_node ++> phys_index[phys_id];
        }

        n_claims_built += 1;
    }
    print(f"[graph] Claim nodes: {n_claims_built}");
    print(f"[graph] Physician nodes: {len(phys_index)}");

    # ── 6. Test traversal: root -> Providers -> Claims ─────────────────────
    print("\n[graph] ── Test traversal ──────────────────────");
    stats = root spawn GraphStats();
    print(f"  Providers visited : {stats.n_providers}");
    print(f"  Fraud providers   : {stats.n_fraud}");
    print(f"  Claims traversed  : {stats.n_claims}");
    print(f"  Total amount (sampled) : ${stats.total_amount:,.0f}");
    print(f"  Reports collected : {len(stats.reports)}");

    fraud_reports = [];
    for r in stats.reports {
        if r["fraud"] == "Yes" {
            fraud_reports.append(r);
        }
    }
    if fraud_reports {
        fp = fraud_reports[0];
        print(f"\n  Sample fraud provider : {fp['provider']}");
        print(f"    Total claims (all)  : {fp['total_claims']}");
        print(f"    Total reimbursed    : ${fp['total_amount']:,.0f}");
    }

    print("[graph] ────────────────────────────────────────");
    print("[graph] Graph build and traversal: OK");
}
