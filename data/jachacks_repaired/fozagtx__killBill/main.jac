"""Demo entry point.

Run with:
    jac run main.jac

Prints a full audit report of `samples/statement_001.csv`, including:
  - every recurring charge the agent found
  - the verdict (KEEP / DOWNGRADE / CANCEL) and the LLM's reason
  - cheaper alternatives the agent suggested
  - drafted cancellation emails
  - HEADLINE NUMBER: total monthly + annual savings
"""
import os;
import from audit { audit_statement_path }

def _hr(ch: str = "=", n: int = 78) -> str {
    return ch * n;
}

def _pad(s: str, n: int) -> str {
    return s + " " * max(0, n - len(s));
}

def _print_report(audit: dict) -> None {
    print(_hr("="));
    print("  SUBSCRIPTION & BILL KILLER  —  audit report");
    print(_hr("="));
    print(f"  Source: {audit['source']}");
    print(f"  Subscriptions reviewed: {audit['subscription_count']}");
    print("");

    keep = [v for v in audit["subscriptions"] if v["verdict"] == "KEEP"];
    downgrade = [v for v in audit["subscriptions"] if v["verdict"] == "DOWNGRADE"];
    cancel = [v for v in audit["subscriptions"] if v["verdict"] == "CANCEL"];

    print(f"  {len(keep)} KEEP   |   {len(downgrade)} DOWNGRADE   |   {len(cancel)} CANCEL");
    print("");

    if cancel {
        print(_hr("-"));
        print("  CANCEL  — recommended kills");
        print(_hr("-"));
        for v in cancel {
            print(f"  X  {_pad(v['merchant'], 30)}  ${v['monthly_cost']:>6.2f}/mo  ->  save ${v['monthly_savings']:>6.2f}/mo");
            print(f"     reason: {v['reason']}");
            if v["cheaper_alternative"] {
                print(f"     alt:    {v['cheaper_alternative']}");
            }
            print("");
        }
    }

    if downgrade {
        print(_hr("-"));
        print("  DOWNGRADE  — keep using, switch to a cheaper plan");
        print(_hr("-"));
        for v in downgrade {
            print(f"  ~  {_pad(v['merchant'], 30)}  ${v['monthly_cost']:>6.2f}/mo  ->  save ${v['monthly_savings']:>6.2f}/mo");
            print(f"     reason: {v['reason']}");
            if v["cheaper_alternative"] {
                print(f"     alt:    {v['cheaper_alternative']}");
            }
            print("");
        }
    }

    if keep {
        print(_hr("-"));
        print("  KEEP  — these earn their cost");
        print(_hr("-"));
        for v in keep {
            print(f"  ok {_pad(v['merchant'], 30)}  ${v['monthly_cost']:>6.2f}/mo");
            if v["reason"] {
                print(f"     reason: {v['reason']}");
            }
        }
        print("");
    }

    # Emails
    emails_drafted = [v for v in audit["subscriptions"] if v.get("email_subject")];
    if emails_drafted {
        print(_hr("-"));
        print("  DRAFTED CANCELLATION EMAILS");
        print(_hr("-"));
        for v in emails_drafted {
            print(f"\n  --- {v['merchant']} ---");
            print(f"  To:      {v['email_send_to']}");
            print(f"  Subject: {v['email_subject']}");
            print(f"\n{v['email_body']}\n");
        }
    }

    # HEADLINE
    print(_hr("="));
    print("  HEADLINE");
    print(_hr("="));
    print(f"      You could save  ${audit['monthly_savings']:>8.2f}  per month");
    print(f"      You could save  ${audit['annual_savings']:>8.2f}  per year");
    print(_hr("="));
}

with entry {
    path = "samples/statement_001.csv";
    print(f"Auditing {path} ...\n");
    audit = audit_statement_path(path);
    _print_report(audit);
}
