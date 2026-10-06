# tests/test_traversal.jac
# Deterministic traversal coverage for the local graph walkers.

import from graph.nodes { FileNode }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }

test "blast radius traversal path populated on connected graph" {
    api = FileNode(path="src/api.py", content="import auth", language="python");
    auth = FileNode(path="src/auth.py", content="", language="python");
    root ++> api;
    api ++> auth;

    result: any = root spawn BlastRadiusMapperWalker(changed_nodes=["src/api.py"]);
    blast: any = getattr(result, "traversal_path", []);
    assert len(blast) > 0, f"blast traversal path is empty: {result}";
}
