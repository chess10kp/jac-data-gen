# ref-l1-print-shop-states
Single-construct refactor: string-typed state field -> enum (string-valued so status text is unchanged).
Idiom targets: >=1 enum; PrintJob.state no longer typed str. Behaviour pinned by status_line text and transitions.
Negatives: cancel allowed from done; finish from queued; enum name (QUEUED) printed instead of value.
