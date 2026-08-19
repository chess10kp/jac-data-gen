walker:priv MyWalker {
    can work with Root entry {
        report "data";
    }
}

def process(item: any) {
    print(item);
}

with entry {
    # Safe single report access
    result = root spawn MyWalker();
    data = result.reports[0] if result.reports else None;

    # Safe with default value
    data = result.reports[0] if result.reports else [];

    # Check length for multiple reports
    if result.reports and len(result.reports) > 1 {
        first = result.reports[0];
        second = result.reports[1];
    }

    # Iterate all reports
    for item in (result.reports if result.reports else []) {
        process(item);
    }
}
