with entry {
    # Write a file
    sandbox.write_file("jac-sbx-abc123", "main.jac", "with entry { print('hello'); }");

    # Read a file
    result = sandbox.read_file("jac-sbx-abc123", "main.jac");
    print(result["content"]);

    # Read binary files (images) -- returned as base64
    result = sandbox.read_file("jac-sbx-abc123", "assets/logo.png");
    # result = {"success": True, "content": "<base64>", "is_binary": True, "mime_type": "image/png"}

    # Delete a file
    sandbox.delete_file("jac-sbx-abc123", "old_file.jac");

    # List files
    result = sandbox.list_files("jac-sbx-abc123");
    for f in result["files"] {
        print(f);
    }
}
