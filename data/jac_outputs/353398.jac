"""Check that header has the minimum mandatory fields."""
def _check_header(header: list[str]) -> list[bool | int] {
    num_samples = 0;
    matching = [];
    mandatory_fields = ["source-ontology", "COLDATA", "VERSION"];
    for field in mandatory_fields {
        matches = [s for s in header if field in s];
        if len(matches) != 0 {
            matching.append(matches);
        }
    }
    all_present = len(matching) == len(mandatory_fields);
    if all_present {
        for line in header {
            if line.startswith("## COLDATA") {
                samples = line.strip().split(": ")[1].strip().split(",");
                num_samples = len(samples);
            }
        }
    }
    return [all_present, num_samples];
}