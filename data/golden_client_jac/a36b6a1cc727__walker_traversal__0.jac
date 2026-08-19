node SecureRoom {
    has clearance_required: int;

    # Generic entry - triggers for ANY walker (no type filter)
    can on_enter with entry {
        print("Someone entered");
    }

    # Typed entry - triggers only for Inspector walkers
    can check_clearance with Inspector entry {
        if visitor.clearance < self.clearance_required {
            print("Access denied");
            disengage;
        }
    }

    # Typed entry for Root walker - in node abilities, the type in
    # 'with Type entry' refers to the *walker* type visiting this node,
    # NOT the node type. This triggers when a walker of type Root visits.
    can at_root with Root entry {
        print("A Root-type walker is visiting this node");
    }

    # Walker exiting
    can on_exit with Inspector exit {
        print("Inspector leaving");
    }

    # Multiple walker types (union)
    can process with Walker1 | Walker2 entry {
        print("Processing for Walker1 or Walker2");
    }
}
