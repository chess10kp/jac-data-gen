with entry {
    result = sandbox.logs("jac-sbx-abc123", offset=0);
    print(result["content"]);
    # result["offset"] contains the byte offset for the next read (streaming)
}
