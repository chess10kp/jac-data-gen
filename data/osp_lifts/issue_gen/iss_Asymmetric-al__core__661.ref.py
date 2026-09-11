from iss_Asymmetric_al__core__661 import AssetGraph


def main() -> None:
    g = AssetGraph()
    g.add_pkg("core")
    g.add_pkg("api", "core")
    g.add_pkg("worker", "core")
    g.add_view("dash", ["api", "worker"])

    assert g.dependency_map("dash") == {
        "upstream": ["api", "worker"],
        "downstream": [],
    }
    assert g.dependency_map("api")["downstream"] == ["dash"]
    assert g.dependency_map("missing") == {"upstream": [], "downstream": []}

    fate, nodes = g.safe_remove("core")
    assert fate == "archived"
    assert sorted(nodes) == ["api", "core", "worker"]
    assert "core" in g.cleanup_view()  # archived pkgs still listed as nodes

    g2 = AssetGraph()
    g2.add_pkg("solo")
    fate2, nodes2 = g2.safe_remove("solo")
    assert fate2 == "deleted"
    assert nodes2 == ["solo"]
    assert g2.cleanup_view() == []

    # diamond adversarial child order
    g3 = AssetGraph()
    g3.add_pkg("root")
    g3.add_pkg("left", "root")
    g3.add_pkg("right", "root")
    g3.add_pkg("leaf", "left")
    g3._children["right"].append("leaf")  # simulate second parent path in map
    g3._parent["leaf"] = "right"
    fate3, _ = g3.safe_remove("root")
    assert fate3 == "deleted"
    print("ok")


if __name__ == "__main__":
    main()
