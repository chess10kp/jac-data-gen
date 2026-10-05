"""Quick agent test: analyze just one subscription end-to-end."""
import os;
import json;
import from audit { analyze_one_subscription, _parse_agent_json }

with entry {
    s = analyze_one_subscription(
        raw_description="Hulu*HULU",
        monthly_cost=17.99,
        months_active=12,
        other_subs_summary="- NETFLIX.COM $22.99/mo\n- Hulu*HULU $17.99/mo\n- SPOTIFY USA $11.99/mo"
    );
    print("");
    print("RAW:", s);
    print("");
    v = _parse_agent_json(s);
    print("PARSED:", v);
    print("verdict:", v.get("verdict"));
    print("reason:", v.get("reason"));
    print("monthly_savings:", v.get("monthly_savings"));
    print("alt:", v.get("cheaper_alternative"));
    print("email subject:", v.get("email_subject"));
}
