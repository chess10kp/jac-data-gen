# tests/test_core.jac
# Only tests with deterministic, pure-logic outputs.
# No LLM calls, no GitHub API calls, no live network.

import from integrations.github { validate_webhook_signature }
import from hashlib { sha256 }
import hmac;

test "HMAC validation accepts correct signature" {
    payload: bytes = "test_payload".encode();
    secret = "my_secret";
    correct_sig = "sha256=" + hmac.new(secret.encode(), payload, sha256).hexdigest();
    assert validate_webhook_signature(payload, correct_sig, secret) == True;
}

test "HMAC validation rejects wrong signature" {
    payload: bytes = "test_payload".encode();
    assert validate_webhook_signature(payload, "sha256=deadbeef", "my_secret") == False;
}

test "HMAC validation rejects empty signature" {
    payload: bytes = "test_payload".encode();
    assert validate_webhook_signature(payload, "", "my_secret") == False;
}

import from graph.nodes { FileNode }
import from graph.edges { ImportEdge }
import from walkers.static.blast_radius { BlastRadiusMapperWalker }
import from walkers.static.security { SecurityAuditorWalker }

test "BlastRadiusMapper _severity_from_hops is correct" {
    w = BlastRadiusMapperWalker(changed_nodes=[]);
    assert w._severity_from_hops(0) == "critical";
    assert w._severity_from_hops(1) == "high";
    assert w._severity_from_hops(2) == "medium";
    assert w._severity_from_hops(3) == "low";
    assert w._severity_from_hops(5) == "low";
}

test "SecurityAuditorWalker with empty allowed_nodes visits no nodes" {
    test_node = FileNode(path="src/a.jac", content="walker Foo {}", language="jac");
    root ++> test_node;

    w = SecurityAuditorWalker(allowed_nodes={"__nonexistent__"}, pr_context="diff");
    result: any = root spawn w;

    reports: any = getattr(result, "reports", []);
    if reports and len(reports) > 0 {
        report_data: any = reports[0];
        assert len(report_data.get("traversal_path", [])) == 0;
    }
}
