1. Only ONE composer job at a time — wait for the current one.
The 5,700-record job is running now (220/5,700, ~1.5h left). Do not start the grinder until it's done, or they'll kill each other's processes. Check it's clear:
pgrep -f cursor_composer_batch   # must return NOTHING before you grind

2. The MCP gotcha (the one that bit us).
The driver disables browsermcp+jac during runs and re-enables on exit. But if a run is hard-killed (Ctrl-C on the parent, /usage-credits login, crash), MCPs get left disabled. Right now they're correctly disabled (job running). After everything finishes, verify + fix:
cursor-agent mcp list                    # both should say "ready"
cursor-agent mcp enable browsermcp; cursor-agent mcp enable jac   # if disabled

3. Watch disk — this is the failure mode that hurt us.
/tmp is RAM (7.5G) and / is at 96% (21G free). The grinder purges per-chunk temp automatically, but if a run dies mid-chunk, temp can linger:
df -h /tmp        # if climbing past ~80%, purge:
find /tmp -maxdepth 1 -name 'tmp*' -user jac -delete 2>/dev/null
find /tmp -maxdepth 1 -name 'jactmp_*' -exec rm -rf {} + 2>/dev/null

4. Monitor progress.
tail -f data/composer_grind.log                    # live chunk-by-chunk log
wc -l data/composer_dataset.jsonl                  # records so far

5. Auth must stay valid. You're logged in as nitinshankarmadhu@gmail.com. If Cursor logs out mid-grind, chunks fail (retry once, then skip). cursor-agent status to check.

Emergency stop

pkill -f composer_grind; pkill -f cursor_composer_batch; pkill -9 -f 'cursor-agent --print'
cursor-agent mcp enable browsermcp; cursor-agent mcp enable jac   # restore MCPs
Then resume later with the same composer_grind.sh 9000 command.

---
Tuning knobs (optional): in the grind command, arg 2 is chunk size (default 2000). In cursor_composer_batch.py calls, --workers 6 is composer concurrency — raise if Cursor tolerates it, lower if you hit rate limits.

Want me to guard the current 5,700-record job when it finishes and hand you a clean starting line, or are you taking it from here?
