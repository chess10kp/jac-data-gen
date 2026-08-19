with entry {
    result = sandbox.create(
        user_id="user-123",
        project_id="my-project",
        code_path="/path/to/project/files"
    );

    if result.success {
        print(f"Sandbox ready at: {result.url}");
        print(f"Sandbox ID: {result.sandbox_id}");
    }
}
