"""
Temporal Anomaly Walker definitions — imported by temporal_agent.jac and synthesis_agent.jac.
No `with entry` block here so imports do not trigger side effects.

Detects four timeline-based fraud patterns:
  overlapping_stays  — patient in two hospitals simultaneously (impossible)
  claim_burst        — provider submits 5+ claims in 7 days (batch fabrication)
  patient_shuttling  — same-day discharge→admission between providers 2+ times
  post_death_claim   — claims filed after recorded death date
"""

include src.graph.schema;

obj TemporalFinding {
    has patient_id: str,
        anomaly_type: str,            # primary detected type
        involved_providers: list[str],
        timeline_evidence: str,       # human-readable date evidence
        risk_level: str,              # "LOW" | "MEDIUM" | "HIGH"
        reasoning: str;
}

def assess_temporal(
    patient_id: str,
    anomaly_types: list[str],
    involved_providers: list[str],
    provider_fraud_labels: list[str],
    timeline_evidence: str,
    deceased: bool,
    dod: str,
    total_claims: int,
) -> TemporalFinding {
    _risk:    str = "LOW";
    _primary: str = "";
    _reasoning: str = "";
    ::py::
    _fpc = sum(1 for lbl in provider_fraud_labels if lbl == "Yes")
    _primary = anomaly_types[0] if anomaly_types else "unknown"
    if "post_death_claim" in anomaly_types:
        _risk = "HIGH"
        _reasoning = (
            f"Post-death billing detected for patient {patient_id} (DOD: {dod}). "
            f"Claims filed after recorded death — definitive fraud. Evidence: {timeline_evidence}"
        )
    elif "overlapping_stays" in anomaly_types and _fpc >= 1:
        _risk = "HIGH"
        _reasoning = (
            f"Overlapping inpatient stays involving {_fpc} fraud-labeled provider(s). "
            f"At least one claim must be fabricated. Evidence: {timeline_evidence}"
        )
    elif "patient_shuttling" in anomaly_types and _fpc >= 2:
        _risk = "HIGH"
        _reasoning = (
            f"Patient shuttling between {_fpc} fraud-labeled providers. "
            f"Coordinated rotation billing pattern. Evidence: {timeline_evidence}"
        )
    elif ("overlapping_stays" in anomaly_types) or \
         ("patient_shuttling" in anomaly_types and _fpc >= 1) or \
         ("claim_burst" in anomaly_types and _fpc >= 1):
        _risk = "MEDIUM"
        _reasoning = (
            f"Temporal anomaly ({', '.join(anomaly_types)}) involving {_fpc} fraud provider(s). "
            f"Evidence: {timeline_evidence}"
        )
    else:
        _risk = "LOW"
        _reasoning = (
            f"Minor temporal anomaly ({', '.join(anomaly_types)}) involving non-fraud providers. "
            f"Evidence: {timeline_evidence}"
        )
    ::py::
    return TemporalFinding(
        patient_id=patient_id,
        anomaly_type=_primary,
        involved_providers=involved_providers,
        timeline_evidence=timeline_evidence,
        risk_level=_risk,
        reasoning=_reasoning
    );
}

walker TemporalAnomalyAgent {
    has deceased_lookup: dict = {},
        provider_fraud: dict = {},
        findings: list[TemporalFinding] = [];

    can on_root with Root entry {
        # Phase 1: collect per-patient claims from Provider→Claim traversal
        pat_claims: dict = {};

        for prov in [-->] {
            self.provider_fraud[prov.id] = prov.fraud_label;
            for claim in [prov -->] {
                bene = claim.bene_id;
                if bene not in pat_claims {
                    pat_claims[bene] = [];
                }
                pat_claims[bene].append({
                    "provider_id": prov.id,
                    "claim_start": claim.claim_start,
                    "claim_end":   claim.claim_end,
                    "claim_type":  claim.claim_type,
                });
            }
        }

        print(f"[temporal] Collected claims for {len(pat_claims)} patients");

        assessed = 0;
        skipped  = 0;

        for bene in pat_claims {
            claims   = pat_claims[bene];
            pat_info = self.deceased_lookup.get(bene, {});
            deceased = False;
            dod_str  = "";
            if pat_info {
                deceased = pat_info.get("deceased", False);
                dod_str  = pat_info.get("dod", "") or "";
            }
            provider_fraud_map = self.provider_fraud;

            # ── All anomaly detection runs inside one Python block ────────
            ::py::
            import datetime as _dt

            def _pd(s):
                """Parse YYYY-MM-DD string to date, return None on failure."""
                try:
                    return _dt.datetime.strptime(s.strip(), '%Y-%m-%d').date() if s else None
                except Exception:
                    return None

            _atypes  = []       # detected anomaly types (in discovery order)
            _iprovs  = set()    # providers involved in any anomaly
            _evid    = []       # human-readable evidence strings

            # ── 1. Post-death claims ──────────────────────────────────────
            if deceased and dod_str:
                _dod = _pd(dod_str)
                if _dod:
                    _dead_claims = [c for c in claims
                                    if _pd(c['claim_start']) and _pd(c['claim_start']) > _dod]
                    if _dead_claims:
                        _atypes.append('post_death_claim')
                        for _c in _dead_claims:
                            _iprovs.add(_c['provider_id'])
                        _ds = sorted(set(_c['claim_start'] for _c in _dead_claims))
                        _evid.append(
                            f"Patient died {dod_str}; "
                            f"{len(_dead_claims)} claim(s) filed after death on: {', '.join(_ds)}"
                        )

            # ── 2. Overlapping inpatient stays ────────────────────────────
            _inp = [
                (c['provider_id'], _pd(c['claim_start']), _pd(c['claim_end']))
                for c in claims
                if c['claim_type'] == 'inpatient'
                and _pd(c['claim_start']) and _pd(c['claim_end'])
            ]
            for _i in range(len(_inp)):
                for _j in range(_i + 1, len(_inp)):
                    _p1, _s1, _e1 = _inp[_i]
                    _p2, _s2, _e2 = _inp[_j]
                    if _p1 != _p2:
                        _olap_s = max(_s1, _s2)
                        _olap_e = min(_e1, _e2)
                        if _olap_s <= _olap_e:
                            if 'overlapping_stays' not in _atypes:
                                _atypes.append('overlapping_stays')
                            _iprovs.update([_p1, _p2])
                            _evid.append(
                                f"Overlapping stays: {_p1}({_s1}→{_e1}) and "
                                f"{_p2}({_s2}→{_e2}) overlap {_olap_s}→{_olap_e}"
                            )

            # ── 3. Claim burst: 5+ claims from same provider within 7 days ─
            _by_prov = {}
            for _c in claims:
                _d = _pd(_c['claim_start'])
                if _d:
                    _by_prov.setdefault(_c['provider_id'], []).append(_d)

            for _p, _pdates in _by_prov.items():
                _pdates_s = sorted(_pdates)
                for _k in range(len(_pdates_s)):
                    _win = [d for d in _pdates_s
                            if 0 <= (d - _pdates_s[_k]).days <= 6]
                    if len(_win) >= 5:
                        if 'claim_burst' not in _atypes:
                            _atypes.append('claim_burst')
                        _iprovs.add(_p)
                        _evid.append(
                            f"Claim burst: {_p} submitted {len(_win)} claims "
                            f"in 7 days ({_pdates_s[_k]}→{_win[-1]})"
                        )
                        break  # one burst report per provider

            # ── 4. Patient shuttling: 2+ same-day discharge→admit transitions ─
            # Sort events so discharge (0) sorts before admission (1) on same day
            _evts = []
            for _c in claims:
                _s = _pd(_c['claim_start'])
                _e = _pd(_c['claim_end'])
                _p = _c['provider_id']
                if _s:
                    _evts.append((_s, 1, _p))   # 1 = admit
                if _e:
                    _evts.append((_e, 0, _p))   # 0 = discharge (sorts first)
            _evts.sort()

            _sht_count = 0
            _sht_provs = set()
            for _k in range(len(_evts) - 1):
                _d1, _t1, _p1 = _evts[_k]
                _d2, _t2, _p2 = _evts[_k + 1]
                if _t1 == 0 and _t2 == 1 and _d1 == _d2 and _p1 != _p2:
                    _sht_count += 1
                    _sht_provs.update([_p1, _p2])
            if _sht_count >= 2:
                _atypes.append('patient_shuttling')
                _iprovs.update(_sht_provs)
                _evid.append(
                    f"Patient shuttling: {_sht_count} same-day discharge→admission "
                    f"transitions between providers {sorted(_sht_provs)}"
                )

            # ── Build output variables for Jac ────────────────────────────
            _iprovs_list = sorted(_iprovs)
            _timeline    = '; '.join(_evid) if _evid else ''
            _has_anomaly = bool(_atypes)
            _priority    = ['post_death_claim', 'overlapping_stays',
                            'patient_shuttling', 'claim_burst']
            _primary     = next((t for t in _priority if t in _atypes),
                                _atypes[0] if _atypes else '')
            _fraud_labels = [provider_fraud_map.get(p, 'Unknown') for p in _iprovs_list]
            ::py::

            if not _has_anomaly {
                skipped += 1;
                continue;
            }

            print(f"[temporal] {bene}: types={_atypes}, providers={_iprovs_list}");

            finding = assess_temporal(
                patient_id           = bene,
                anomaly_types        = _atypes as list[str],
                involved_providers   = _iprovs_list as list[str],
                provider_fraud_labels = _fraud_labels as list[str],
                timeline_evidence    = _timeline as str,
                deceased             = deceased,
                dod                  = dod_str,
                total_claims         = len(claims),
            );

            # Override factual fields — LLM must not invent these
            finding.patient_id         = bene;
            finding.anomaly_type       = _primary as str;
            finding.involved_providers = _iprovs_list as list[str];
            finding.timeline_evidence  = _timeline as str;

            # Post-LLM risk corrections
            if "post_death_claim" in _atypes {
                finding.risk_level = "HIGH";
            } elif "overlapping_stays" in _atypes and finding.risk_level == "LOW" {
                finding.risk_level = "MEDIUM";
            }

            self.findings.append(finding);
            assessed += 1;
            report finding;

            print(f"  → risk={finding.risk_level}, type={finding.anomaly_type}\n");
        }

        print(f"[temporal] Assessed: {assessed}, skipped: {skipped}");
    }
}
