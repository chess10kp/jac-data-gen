def example() {
    with open("file.txt") as f {
        content = f.read();
    }

    # Multiple context managers
    with open("in.txt") as fin, open("out.txt", "w") as fout {
        fout.write(fin.read());
    }
}
