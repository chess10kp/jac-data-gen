import from services.models { Project, ProjectMutationResult }
import from services.crawler { validate_url_candidate, now_iso }

def:pub create_project(name: str, url: str) -> ProjectMutationResult {
    clean_name: str = name.strip();
    if len(clean_name) == 0 {
        return ProjectMutationResult(ok=False, message="Project name is required.", project=None);
    }
    safety = validate_url_candidate(url);
    if not safety.ok {
        return ProjectMutationResult(ok=False, message=safety.reason, project=None);
    }
    created = root ++> Project(
        name=clean_name,
        live_url=safety.final_url,
        created_at=now_iso(),
    );
    project: Project = (created[0] as Project);
    project.uid = jid(project); # jac:ignore[E1005]
    return ProjectMutationResult(ok=True, message="Project created.", project=project);
}

def:pub list_projects() -> list[Project] {
    projects: list[Project] = [];
    for project in [root -->][?:Project] {
        project.uid = jid(project); # jac:ignore[E1005]
        projects.append(project);
    }
    return projects;
}
