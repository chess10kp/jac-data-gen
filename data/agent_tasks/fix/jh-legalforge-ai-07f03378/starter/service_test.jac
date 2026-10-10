"""Minimal test service."""

walker analyze {
    has contract_text: str = "";
    has title: str = "Test";
    has jurisdiction: str = "US";
    has party_perspective: str = "buyer";
    has token: str = "";

    obj __specs__ {
        static has auth: bool = False;
    }

    can go with `root entry {
        print("ENTERED");
        clauses = [];
        text = self.contract_text;
        ::py::
        import re
        parts = re.split(r"\n(?=\d+(?:\.\d+)?\s)", (text or "").strip())
        rows = []
        for i, part in enumerate(parts):
            part = part.strip()
            if not part:
                continue
            m = re.match(r"^(\d+(?:\.\d+)?)\s*(.*)$", part, re.S)
            if m:
                rows.append({"id": m.group(1), "text": part[:80]})
        clauses = rows
        ::py::
        print(f"PARSED {len(clauses)} clauses");
        report {"status": "ok", "title": self.title, "clauses": len(clauses)};
    }
}

walker health {
    obj __specs__ {
        static has auth: bool = False;
        static has methods: list = ["get", "post"];
    }
    can go with `root entry {
        report {"status": "healthy"};
    }
}

with entry {
    print("Service test started");
}
