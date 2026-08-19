def _amount(record: dict) -> int {
    amount = record["amount"];
    if not isinstance(amount, int) {
        raise ValueError(f"non-integer amount: {amount}");
    }
    if amount < 0 {
        raise ValueError(f"negative amount: {amount}");
    }
    return amount;
}

def _summary(total: int, ok: int, bad: list) -> str {
    if len(bad) == 0 {
        return f"total={total} ok={ok}";
    }
    return f"total={total} ok={ok} bad={','.join(bad)}";
}

def audit_records(records: list) -> str {
    total = 0;
    ok = 0;
    bad = [];
    for record in records {
        try {
            total += _amount(record);
            ok += 1;
        } except KeyError {
            bad.append(record.get("id", "?") + ":missing");
        } except ValueError {
            bad.append(record.get("id", "?") + ":invalid");
        }
    }
    return _summary(total, ok, bad);
}

with entry {
    print(audit_records([{'id': 'a', 'amount': 10}, {'id': 'b', 'amount': 5}]));
}
