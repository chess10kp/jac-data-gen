import from ..graph.nodes { Drug }
import from ..graph.edges { Interaction }
import os;

walker:pub test_walker {
    has test_field: str = "hello";

    can run with Root entry {
        drugs = [here -->[?:Drug]];
        report {"drug_count": len(drugs), "field": self.test_field};
        disengage;
    }
}
