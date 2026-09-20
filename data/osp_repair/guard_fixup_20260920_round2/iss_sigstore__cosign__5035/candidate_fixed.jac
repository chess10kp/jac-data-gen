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
        visit [-->];
    }

    can publish_phase with Phase entry {
        line = f"[PHASE {here.order}] {here.name}: "
            f"{'OK' if not here.failed else 'FAILED: ' + here.failure_reason}";
        self.notes.append(line);
        print(line);
        # Phase-attached publication steps, then linear phase ordering.
        visit [->:Succeeds:->];
        visit [->:PublishedBy:->];
        visit [->:DiscoveryFor:->];
        visit [-->];
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
        if here.attempt >= 1 {
            skip;
        }
        here.attempt += 1;
        note = (f"  fallback discovery-index {here.tag} attempt "
                f"#{here.attempt} (conditional update)");
        self.notes.append(note);
        print(note);
        # Follow typed conflict/cycle edges for lost-update detection.
        visit [->:Conflicts:->];
    }

    can detect_conflict with DiscoveryIndex entry {
        if here.attempt < 1 {
            skip;
        }
        # Re-entry after the first attempt indicates a lost-update cycle.
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