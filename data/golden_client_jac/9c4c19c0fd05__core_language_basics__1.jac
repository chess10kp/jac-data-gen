with entry {
    result = sandbox.exec_command("jac-sbx-abc123", "ls -la /app", timeout=30);
    print(result["stdout"]);
}
