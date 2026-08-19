import from byllm.types { IterationAction, IterationContext }

def search(query: str) -> str { return query; }
def read_file(path: str) -> str { return path; }
def write_file(path: str, content: str) -> bool { return True; }

def my_hook(ctx: IterationContext) -> IterationAction {
    # Stop after 5 iterations
    if ctx.iteration > 5 {
        return IterationAction.ABORT;
    }
    # Stop if too many tokens used
    if ctx.total_tokens > 10000 {
        return IterationAction.ABORT_WITH_SUMMARY;
    }
    return IterationAction.CONTINUE;
}

def agent_task(question: str) -> str by llm(
    tools=[search, read_file, write_file],
    on_iteration=my_hook
);
