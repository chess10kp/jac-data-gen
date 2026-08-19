with entry {
    # Check status
    status = sandbox.status("jac-sbx-abc123");
    print(f"State: {status.state}");  # pending, starting, running, stopped, error

    # List user's sandboxes
    sandboxes = sandbox.list_sandboxes("user-123");
    for s in sandboxes {
        print(f"{s.sandbox_id}: {s.state} - {s.url}");
    }

    # Stop a sandbox
    sandbox.stop("jac-sbx-abc123");

    # Destroy and clean up all resources
    sandbox.destroy("jac-sbx-abc123");

    # Clean up expired sandboxes (beyond TTL)
    cleaned = sandbox.cleanup_expired();
    print(f"Cleaned {cleaned} expired sandboxes");
}
