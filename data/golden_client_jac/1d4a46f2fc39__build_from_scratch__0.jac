import argparse;

with entry {
    parser = argparse.ArgumentParser();
    parser.add_argument("--name");
    args = parser.parse_args();
    print(f"Hello, {args.name}!");
}
