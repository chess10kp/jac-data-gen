node Room {
    can on_enter with Visitor entry {
        print("Entering room");
    }

    can on_exit with Visitor exit {
        print("Exiting room");
    }
}
