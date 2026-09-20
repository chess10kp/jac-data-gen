import io;
import from contextlib { redirect_stdout }

test "manifest-last rejects pending blob refs without rolling back committed layers" {
    p2 = Phase(name="upload-blobs", order=2);
    p3 = Phase(name="publish-manifest", order=3);
    config = Blob(alias="config", digest="sha256:cfg", state="pending");
    layer1 = Blob(alias="layer-1", digest="sha256:l1", state="committed");
    manifest = ArtifactManifest(digest="sha256:m", state="pending");
    manifest +>:Refers(alias="config"):+> config;
    manifest +>:Refers(alias="layer-1"):+> layer1;
    root ++> p2 ++> p3;
    p2 +>:Succeeds:+> layer1;
    p3 +>:PublishedBy(phase="publish-manifest"):+> manifest;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Publisher(artifact_name="partial-fail");
    }
    out = buf.getvalue();
    assert "manifest REJECTED" in out, f"expected manifest rejection: {out}";
    assert "blob config not committed" in out, f"missing config rejection detail: {out}";
    assert "NO ROLLBACK" in out, f"missing no-rollback contract message: {out}";
    assert manifest.state == "pending", f"manifest must stay pending: {manifest.state}";
    assert layer1.state == "committed", f"committed layer must be preserved: {layer1.state}";
    assert config.state == "pending", f"unuploaded config must remain pending: {config.state}";
}

test "manifest commits when every referenced blob is already committed" {
    p3 = Phase(name="publish-manifest", order=3);
    config = Blob(alias="config", digest="sha256:cfg", state="committed");
    layer1 = Blob(alias="layer-1", digest="sha256:l1", state="committed");
    manifest = ArtifactManifest(digest="sha256:m", state="pending");
    manifest +>:Refers(alias="config"):+> config;
    manifest +>:Refers(alias="layer-1"):+> layer1;
    root ++> p3;
    p3 +>:PublishedBy(phase="publish-manifest"):+> manifest;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Publisher(artifact_name="happy-path");
    }
    out = buf.getvalue();
    assert "artifact manifest committed" in out, f"expected manifest commit log: {out}";
    assert manifest.state == "committed", f"manifest should be committed: {manifest.state}";
}

test "upload_blob is idempotent for already committed blobs" {
    p2 = Phase(name="upload-blobs", order=2);
    blob = Blob(alias="config", digest="sha256:cfg", state="committed");
    root ++> p2;
    p2 +>:Succeeds:+> blob;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Publisher(artifact_name="blob-retry");
    }
    out = buf.getvalue();
    assert "already committed (idempotent)" in out, f"missing idempotent retry note: {out}";
    assert blob.state == "committed", f"blob must remain committed: {blob.state}";
}

test "discovery re-entry triggers lost-update conflict guard" {
    p4 = Phase(name="update-discovery-index", order=4);
    disc = DiscoveryIndex(tag="sha256-ref-1", state="pending", attempt=0);
    root ++> p4;
    p4 +>:DiscoveryFor(tag="sha256-ref-1"):+> disc;
    disc +>:Conflicts:+> disc;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Publisher(artifact_name="disc-conflict");
    }
    out = buf.getvalue();
    assert "CONFLICT" in out, f"expected conflict detection: {out}";
    assert "lost-update guarded" in out, f"missing lost-update guard message: {out}";
}

test "auditor marks committed blobs and manifests as protected from rollback" {
    blob = Blob(alias="config", digest="sha256:cfg", state="committed");
    manifest = ArtifactManifest(digest="sha256:m", state="committed");
    root ++> blob;
    root ++> manifest;

    aud = root spawn Auditor();
    protected_count = 0;
    for f in aud.findings {
        if "PROTECTED" in f {
            protected_count += 1;
        }
    }
    assert protected_count >= 2,
        f"expected protected blob and manifest findings: {aud.findings}";
}