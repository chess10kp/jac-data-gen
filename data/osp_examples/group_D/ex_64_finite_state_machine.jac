"""Vending machine controller as a finite state machine.

States are nodes and transitions are typed edges (InsertCoin, PressButton,
Reset). The runner picks the edge type at runtime by assigning it to a bare
variable first -- the edge-type slot of a visit cannot hold an expression --
then rides the matching transition for each input symbol.
"""

node State {
    has name: str;
}

edge InsertCoin: State --> State {}
edge PressButton: State --> State {}
edge Reset: State --> State {}

walker MachineRunner {
    has machine_name: str;
    has inputs: list[str] = [];
    has step_idx: int = 0;
    has trail: list[str] = [];
    has transition_table: dict = {};

    can step with State entry {
        self.trail.append(here.name);

        if self.step_idx >= len(self.inputs) {
            print(f"{self.machine_name} run: {' -> '.join(self.trail)}");
            disengage;
        }

        label = self.inputs[self.step_idx];
        self.step_idx += 1;
        t = self.transition_table[label];  # edge type as a runtime value
        visit [->:t:->];
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:State] {
        del stale_node;
    }
    idle = State(name="idle");
    waiting = State(name="waiting");
    vend = State(name="vend");

    idle +>: InsertCoin() :+> waiting;
    waiting +>: InsertCoin() :+> waiting;
    waiting +>: PressButton() :+> vend;
    vend +>: Reset() :+> idle;

    # Session 1: two coins then a button press ends in the vend state.
    session1 = MachineRunner(
        machine_name="session1",
        inputs=["coin", "coin", "button"],
    );
    session1.transition_table = {
        "coin": InsertCoin,
        "button": PressButton,
        "reset": Reset,
    };
    idle spawn session1;

    # Session 2: coin, button, vend, reset -- a full purchase cycle.
    session2 = MachineRunner(
        machine_name="session2",
        inputs=["coin", "button", "reset"],
    );
    session2.transition_table = session1.transition_table;
    idle spawn session2;
}
