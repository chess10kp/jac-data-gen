import from ..graph.nodes { Drug }

walker:pub test_walker {
    has test_field: str = "hello";

    can run with Root entry {
        drugs = [here -->[?:Drug]];
        report {"drug_count": len(drugs)};
        disengage;
    }
}
