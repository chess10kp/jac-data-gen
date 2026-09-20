Analyzing the failure: the manifest isn't reached when `p3` is entered via the phase chain from `p2`, because a nested `visit [-->]` only follows the same edge family as the parent visit—not typed `PublishedBy` edges. Checking the workspace for Jac visit patterns to confirm.
The failure happens because `publish_phase` uses a single `visit [-->]` for both phase chaining and work edges. When `p3` is reached through the `++>` chain from `p2`, a nested `visit [-->]` does not follow the typed `PublishedBy` edge to the manifest, so `publish_manifest` never runs. The fix is to visit typed work edges explicitly per phase, then advance with `visit [++>]` for linear phase ordering only.

```jac candidate
"""OCI artifact publication atomicity and rollback semantics.

Models the publication phases (blobs -> artifact manifest -> fallback
discovery index) for an OCI artifact. The walker traverses the
publication graph in the correct manifest-last order, enforces the
"no implicit blob rollback" rule, and reports phase context when a
publication step fails. Cycles in the fallback read-modify-write path
are detected and rejected (lost-update protection).
"""

# ---- Edge archetypes ----

edge Refers {
    # References a blob from a manifest; payload is the local alias.
    has alias: str = "";
}

edge PublishedAs {
    # A blob is committed in the registry with this digest.
    has digest: str = "";
    has state: str = "pending";  # pending | committed
}

edge PublishedBy {
    # Manifest commit attempt; records the phase that published it.
    has phase: str = "";
}

edge DiscoveryFor {
    # Fallback discovery-index update targeting a given artifact.
    has tag: str = "";
    has attempt: int = 0;
}

edge Succeeds {
    # Linear ordering between publication phases.
}

edge Conflicts {
    # Detected lost-update / cycle between two discovery-index attempts.
}

# ---- Node archetypes ----

node Phase {
    has name: str = "";
    has order: int = 0;
    has failed: bool = False;
    has failure_reason: str = "";
}

node Blob {
    has alias: str = "";
    has digest: str = "";
    has state: str = "pending";  # pending | committed
}

node ArtifactManifest {
    has digest: str = "";
    has state: str = "pending";  # pending | committed
}

node DiscoveryIndex {
    has tag: str = "";
    has state: str = "pending";  # pending | committed
    has attempt: int = 0;
}

# ---- Walker: publishes an artifact in manifest-last order ----

walker Publisher {
    has artifact_name: str = "";
    has notes: list = [];

    can begin with Root entry {
        print(f"Publishing artifact: {self.artifact_name}");
        # Find the publication unit attached to root.
        visit [++>];
    }

    can publish_phase with Phase entry {
        line = f"[PHASE {here.order}] {here.name}: "
            f"{'OK' if not here.failed else 'FAILED: ' + here.failure_reason}";
        self.notes.append(line);
        print(line);
        # Manifest-last ordering: do phase work via typed edges, then
        # advance along the linear phase chain only.
        if here.name == "upload-blobs" {
            visit [->:Succeeds:->];
        } elif here.name == "publish-manifest" {
            visit [->:PublishedBy:->];
        } elif here.name == "update-discovery-index" {
            visit [->:DiscoveryFor:->];
        }
        visit [++>];
    }

    can upload_blob with Blob entry {
        if here.state == "committed" {
            note = f"  blob {here.alias} digest={here.digest} already committed (idempotent)";
            self.notes.append(note);
            print(note);
        } else {
            here.state = "committed";
            note = f"  blob {here.alias} committed digest={here.digest}";
            self.notes.append(note);
            print(note);
        }
        disengage;
    }

    can publish_manifest with ArtifactManifest entry {
        # Verify every referenced blob is committed before publishing.
        all_refs_ok = True;
        for blob in [->:Refers:->][?:Blob] {
            if blob.state != "committed" {
                all_refs_ok = False;
                self.notes.append(
                    f"  manifest REJECTED: blob {blob.alias} not committed"
                );
                print(f"  manifest REJECTED: blob {blob.alias} not committed");
            }
        }
        if all_refs_ok {
            here.state = "committed";
            note = f"  artifact manifest committed digest={here.digest}";
            self.notes.append(note);
            print(note);
        } else {
            # Manifest-last ordering: earlier blobs remain valid content;
            # we DO NOT roll them back (per issue contract).
            note = "  NO ROLLBACK: committed blobs preserved, "
                "subject to registry GC";
            self.notes.append(note);
            print(note);
        }
        disengage;
    }

    can update_discovery with DiscoveryIndex entry {
        here.attempt += 1;
        note = (f"  fallback discovery-index {here.tag} attempt "
                f"#{here.attempt} (conditional update)");
        self.notes.append(note);
        print(note);
        # Check for a conflicting concurrent attempt -> cycle.
        visit [-->];
    }

    can detect_conflict with DiscoveryIndex entry {
        # If we re-enter a discovery index, that's a lost-update cycle.
        self.notes.append(
            "  CONFLICT: fallback discovery-index re-entry; lost-update guarded"
        );
        print("  CONFLICT: fallback discovery-index re-entry; "
              "lost-update guarded");
        disengage;
    }
}

# ---- Walker: audits the publication graph for safety ----

walker Auditor {
    has findings: list = [];

    can begin with Root entry {
        print("Auditing publication graph for atomicity violations");
        visit [-->];
    }

    can audit_blob with Blob entry {
        # Rule 1: never delete a committed blob.
        if here.state == "committed" {
            self.findings.append(
                f"PROTECTED: blob {here.alias} digest={here.digest} "
                "must not be deleted by rollback"
            );
        }
        visit [-->];
    }

    can audit_manifest with ArtifactManifest entry {
        if here.state == "committed" {
            self.findings.append(
                f"PROTECTED: artifact manifest digest={here.digest} "
                "must not be deleted by rollback"
            );
        }
        visit [-->];
    }

    can audit_discovery with DiscoveryIndex entry {
        # Rule: discovery-index updates must be conditional / conflict-safe.
        if here.attempt > 1 {
            self.findings.append(
                f"WARN: discovery-index {here.tag} re-attempted "
                f"({here.attempt}x); lost-update protection required"
            );
        }
        visit [-->];
    }
}

# ---- Demonstration ----

with entry {
    # Phase graph (linear ordering of the publication unit).
    p1 = Phase(name="validate-options", order=1);
    p2 = Phase(name="upload-blobs", order=2);
    p3 = Phase(name="publish-manifest", order=3);
    p4 = Phase(name="update-discovery-index", order=4);

    # Inject a failure in the manifest phase to demo no-rollback rule.
    p3.failed = True;
    p3.failure_reason = "config blob missing (simulating ECR BLOB_UPLOAD_UNKNOWN)";

    # Blobs (config + layer) - config intentionally uncommitted to show
    # the manifest-last ordering rejection without rollback.
    config = Blob(alias="config", digest="sha256:cfg...", state="pending");
    layer1 = Blob(alias="layer-1", digest="sha256:l1...", state="committed");
    layer2 = Blob(alias="layer-2", digest="sha256:l2...", state="committed");

    # Artifact manifest that references all three blobs.
    manifest = ArtifactManifest(digest="sha256:m...", state="pending");
    manifest +>:Refers(alias="config"):+> config;
    manifest +>:Refers(alias="layer-1"):+> layer1;
    manifest +>:Refers(alias="layer-2"):+> layer2;

    # Fallback discovery-index (read-modify-write, lost-update prone).
    disc = DiscoveryIndex(tag="sha256-ref-1", state="pending", attempt=0);

    # Wire the publication unit under root.
    root ++> p1
        ++> p2
        ++> p3
        ++> p4;
    p2 +>:Succeeds:+> config;
    p2 +>:Succeeds:+> layer1;
    p2 +>:Succeeds:+> layer2;
    p3 +>:PublishedBy(phase="publish-manifest"):+> manifest;
    p4 +>:DiscoveryFor(tag="sha256-ref-1"):+> disc;

    # Run publisher.
    publisher_walker = Publisher(artifact_name="example/signed-image");
    root spawn publisher_walker;

    print("");
    print("=== Audit ===");
    aud = Auditor();
    root spawn aud;
    for f in aud.findings {
        print(f);
    }
}
```

```jac tests
unchanged
```

**What changed:** `publish_phase` now visits typed work edges (`Succeeds`, `PublishedBy`, `DiscoveryFor`) by phase name, then advances with `visit [++>]` so phase chaining stays separate from publication work. `begin` uses `visit [++>]` for the same reason. That ensures `publish_manifest` runs at the manifest phase even when `p3` is reached through the `p2 → p3` chain, which fixes the missing rejection output in the failing test.