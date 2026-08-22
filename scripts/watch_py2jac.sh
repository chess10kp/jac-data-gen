#!/bin/bash
# Watch composer_grind (chunk_19000) to completion; notify via notify-send.
GRIND_PID=310774
MASTER=data/composer_dataset.jsonl
LOG=data/composer_grind.log

while true; do
    if ! kill -0 "$GRIND_PID" 2>/dev/null; then
        N=$(wc -l < "$MASTER" 2>/dev/null || echo "?")
        LAST=$(tail -3 "$LOG" | tr '\n' ' ' | cut -c1-160)
        notify-send -u critical -t 0 "py2jac grind FINISHED" \
            "chunk_19000 done. master=${N}/15000
tail: ${LAST}"
        echo "[$(date +%H:%M:%S)] grind exited; master=${N}; notified" >> /tmp/watch_py2jac.log
        exit 0
    fi
    if ! pgrep -f "jac test|jac check" >/dev/null 2>&1 && ! pgrep -f "agent_idiomize_guard" >/dev/null; then
        # no workers but grind alive = wedged
        STUCK=$(ps -o etime= -p "$GRIND_PID" 2>/dev/null | tr -d ' ')
        notify-send -u critical -t 0 "py2jac grind STALLED" \
            "PID ${GRIND_PID} alive ${STUCK} but no jac test/check workers.
Check: pstree -ap ${GRIND_PID}"
        echo "[$(date +%H:%M:%S)] stall detected (workers gone, grind alive)" >> /tmp/watch_py2jac.log
    fi
    sleep 300
done
