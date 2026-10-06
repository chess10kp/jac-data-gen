import from app.models.workflow { WorkflowRequest }
import from app.models.outputs { WorkflowResultBundle }
import from app.services.memory_store { remember_session, update_project_memory, get_project_memory }

def:pub run_decision_memory(request: WorkflowRequest, bundle: WorkflowResultBundle) -> dict {
    remember_session(request, bundle);
    return update_project_memory(request.repo_path, bundle);
}

def:pub load_decision_memory(repo_path: str) -> dict {
    return get_project_memory(repo_path);
}
