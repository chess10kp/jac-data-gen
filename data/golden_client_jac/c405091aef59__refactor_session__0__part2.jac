walker:priv MyWalker {
    can work with Root entry;
}

impl MyWalker.work {
    report "data";
}

def first_report(reports: list, fallback: any) -> any {
    return reports[0] if reports else fallback;
}

def process(item: any) {
    print(item);
}

with entry {
    result = root spawn MyWalker();

    data = first_report(result.reports, None);
    data = first_report(result.reports, []);

    if result.reports and len(result.reports) > 1 {
        first = result.reports[0];
        second = result.reports[1];
    }

    for item in (result.reports if result.reports else []) {
        process(item);
    }
}
