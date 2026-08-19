# One storage instance for the module, configured once.
glob storage = store(base_path="./uploads", create_dirs=True);

with entry {
    print(f"storage ready at ./uploads");
}
