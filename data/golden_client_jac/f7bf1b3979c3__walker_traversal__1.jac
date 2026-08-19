node Item { has name: str = ""; }

walker Example {
    can traverse with Item entry {
        print("Visiting");
        visit [-->];  # Nodes queued, visited AFTER this method
        print("This prints before visiting children");
    }
}
