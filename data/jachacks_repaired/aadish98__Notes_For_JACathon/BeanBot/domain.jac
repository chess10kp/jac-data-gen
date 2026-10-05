# Shared types for BeanBot

enum Role {
    MANAGER,
    EMPLOYEE
}

enum TaskStatus {
    PLANNED,
    IN_PROGRESS,
    COMPLETED,
    OVERDUE
}

enum Intent {
    ADD_TASK,
    UPDATE_TASK,
    ADD_COMMENT,
    MARK_COMPLETE,
    VIEW_TASKS,
    CANCEL_PENDING,
    UNKNOWN
}

obj TaskDraft {
    has title: str = "";
    has project_id: str = "";
    has assignee_id: str = "";
    has assignee_name: str = "";
    has start_date: str = "";
    has due_date: str = "";
    has expected_end_date: str = "";
    has status: str = "";
    has description: str = "";
    has time_estimate: str = "";
    has deliverable_spec: str = "";
    has notebook_location: str = "";
    has result_schema_json: str = "";
    has result_summary: str = "";
    has data_link: str = "";
    has blocked_reason: str = "";
    has task_id: str = "";
    has body: str = "";
}

obj ChatParse {
    has intent: Intent = Intent.UNKNOWN;
    has fields: TaskDraft = TaskDraft();
}
