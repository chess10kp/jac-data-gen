import from byllm.lib { CompactionNotEffectiveError }

with entry {
    try {
        result = my_long_running_agent(query);
    } except CompactionNotEffectiveError as e {
        print(f"Context could not be compacted: {e}");
        # Recovery options:
        # 1. Provide a more aggressive on_compaction hook
        # 2. Increase ctx_window if the model supports it
        # 3. Switch to a model with a larger context window
        # 4. Reduce keep_recent_iterations to discard more history
    }
}
