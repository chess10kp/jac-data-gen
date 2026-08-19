with entry {
    parser = argparse.ArgumentParser();
    parser.add_argument("--name", default="World");
    parser.add_argument("--greeting");
    args = parser.parse_args();
    print(f"{args.greeting}, {args.name}!");
}
