import from datetime { datetime }
import from app.models.workflow { WorkflowRequest }
import from app.models.outputs { WorkflowResultBundle }

glob SESSION_RUNS: list[dict] = [];
glob PROJECT_MEMORY: dict[str, dict] = {};

def:pub remember_session(request: WorkflowRequest, bundle: WorkflowResultBundle) -> dict {
    saved_at = str(datetime.now());
    record = {
        "repo_path": request.repo_path,
        "mode": request.mode,
        "prompt": request.prompt,
        "saved_at": saved_at,
        "headline": bundle.action_plan.headline
    };
    SESSION_RUNS.append(record);
    return record;
}

def:pub recent_session_runs() -> list[dict] {
    return SESSION_RUNS;
}

def:pub update_project_memory(repo_path: str, bundle: WorkflowResultBundle) -> dict {
    key = repo_path or "default";
    updated_at = str(datetime.now());
    PROJECT_MEMORY[key] = {
        "decisions": [item.title for item in bundle.decisions],
        "blockers": [item.title for item in bundle.blockers],
        "tickets": [item.title for item in bundle.tickets],
        "updated_at": updated_at
    };
    return PROJECT_MEMORY[key];
}

def:pub get_project_memory(repo_path: str) -> dict {
    key = repo_path or "default";
    return PROJECT_MEMORY.get(key, {"decisions": [], "blockers": [], "tickets": [], "updated_at": ""});
}
