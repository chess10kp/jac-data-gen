with entry {
    # ADMIN/MAINTENANCE ONLY -- scans every root in the system.
    total = 0;
    processed = 0;
    for r in allroots() {
        total += 1;
        try {
            # ... per-root cleanup work on r ...
            processed += 1;
        } except Exception as e {
            print(f"skip root {total}: {e}");
        }
    }
    print(f"cleanup complete: processed {processed}/{total} roots");
}
