def example() {
    with open("file.txt") as f {
        for line in f {
            print(line);
        }
    }
    with open("in.txt") as fin, open("out.txt", "w") as fout {
        for line in fin {
            fout.write(line);
        }
    }
}
