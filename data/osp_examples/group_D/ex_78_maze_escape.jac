"""Maze escape with depth-first search.

The maze is a grid of cells joined by Corridor edges where walls leave
gaps. A runner walker explores depth-first by inserting next cells at the
front of its visit queue, marks dead ends as visited so they are never
re-entered, and reports the escape route when it steps onto the exit
cell.
"""

node Cell {
    has label: str;
    has is_exit: bool = False;
    has seen: bool = False;
}

edge Corridor: Cell --> Cell {}

walker MazeRunner {
    has path: list[str] = [];
    has explored: int = 0;

    can explore with Cell entry {
        if here.seen {
            skip;  # dead end or already-on-path cell
        }
        here.seen = True;
        self.explored += 1;
        self.path.append(here.label);

        if here.is_exit {
            route = " -> ".join(self.path);
            print(f"Escaped after exploring {self.explored} cells!");
            print(f"Path: {route}");
            disengage;
        }

        # Front-of-queue insertion => depth-first probing.
        visit : 0 : [->:Corridor:->];
    }
}

with entry {
    for stale in [root -->][?:Cell] {
        del stale;
    }

    # 4x4 grid; '#' cells are walls and simply have no corridors through.
    grid = {};
    labels = [
        ["A1", "A2", "#", "A4"],
        ["B1", "B2", "#", "B4"],
        ["C1", "C2", "C3", "C4"],
        ["D1", "#", "#", "D4"],
    ];
    for row in labels {
        for lab in row {
            if lab != "#" {
                grid[lab] = Cell(label=lab);
            }
        }
    }

    open_pairs = [
        ["A1", "A2"], ["A1", "B1"],
        ["A2", "B2"], ["B1", "C1"], ["B2", "C2"],
        ["A4", "B4"], ["B4", "C4"],
        ["C1", "D1"], ["C1", "C2"], ["C2", "C3"],
        ["C3", "C4"], ["C4", "D4"],
    ];
    start_cell = grid["A1"];
    exit_cell = grid["D4"];
    exit_cell.is_exit = True;

    # Corridors are two-way: an edge in each direction.
    for pair in open_pairs {
        cell_a = grid[pair[0]];
        cell_b = grid[pair[1]];
        cell_a +>: Corridor() :+> cell_b;
        cell_b +>: Corridor() :+> cell_a;
    }

    root ++> start_cell;
    start_cell spawn MazeRunner();
}
