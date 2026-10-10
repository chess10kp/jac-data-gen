include graph.nodes;

walker :pub test_walker {
    has test_field: str = "hello";
    
    can run with `root entry {
        drugs = [here -->][?:Drug];
        report {"drug_count": len(drugs)};
        disengage;
    }
}
