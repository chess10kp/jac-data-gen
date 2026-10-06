import from ..services.projects { create_project, list_projects }
import from ..services.models { Project, ProjectMutationResult }

obj ProjectsState {
    has projects: list[Project] = [];
    has loading: bool = True;
    has error: str = "";
    has refresh: any = None;
    has createProject: any = None;
}

def:pub useProjects() -> ProjectsState {
    has projects: list[Project] = [];
    has loading: bool = True;
    has error: str = "";

    async def refresh() -> None {
        loading = True;
        error = "";
        try {
            loaded_projects: list[Project] = [];
            loaded_projects = await list_projects();
            projects = loaded_projects;
        } except Exception as e {
            error = "Could not load projects: " + str(e);
        }
        loading = False;
    }

    async def createProject(name: str, url: str) -> ProjectMutationResult | None {
        error = "";
        try {
            response: ProjectMutationResult | None = None;
            response = await create_project(name, url);
            if response is not None and response.ok and response.project is not None {
                projects = projects + [response.project];
            } elif response is not None {
                error = str(response.message);
            }
            return response;
        } except Exception as e {
            error = "Could not create project: " + str(e);
        }
        return None;
    }

    async can with entry {
        await refresh();
    }

    return ProjectsState(
        projects=projects,
        loading=loading,
        error=error,
        refresh=refresh,
        createProject=createProject,
    );
}
