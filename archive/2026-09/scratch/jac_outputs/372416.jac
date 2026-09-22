"""Return nested field sets per level from a benchmark JSON entry."""
def traverse_fields(`entry: dict[str, object], ignore_fields: list[str] | None = None) -> list[set[str]] {
    ignore_set = {
        'timestamp',
        'tvm_hash',
        'detailed',
        'start_time',
        'end_time',
        'time_delta',
        'success',
        'run_cpu_telemetry',
        'run_gpu_telemetry'
    };
    if ignore_fields is not None {
        ignore_set = set(ignore_fields);
    }
    level_fields = {
        field
        for field in `entry.keys()
        if field not in ignore_set
    };
    values_to_check = [
        `entry[field]
        for field in level_fields
        if isinstance(`entry[field], dict)
    ];
    tail = [];
    max_len = 0;
    for value in values_to_check {
        next_fields = traverse_fields(value);
        tail.append(next_fields);
        if len(next_fields) > max_len {
            max_len = len(next_fields);
        }
    }
    final_tail = [];
    for i in range(max_len) {
        u = set({});
        final_tail.append(
            u.union(
                *[
                    fields_list[i]
                    for fields_list in tail
                    if len(fields_list) > i
                ]
            )
        );
    }
    return [level_fields] + final_tail;
}