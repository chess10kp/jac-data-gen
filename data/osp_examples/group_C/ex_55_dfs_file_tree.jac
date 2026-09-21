"""Walk a source tree depth-first to flag oversized files.

The tree branches at every directory, so traversal order matters: the
auditor wants full subdirectory dives before moving sideways. Inserting
each new batch of children at the front of the visit queue (index 0)
produces exactly that depth-first order, and the printed trail proves it.
"""

node Folder {
    has name: str;
}

node FileNode {
    has name: str;
    has kb: int;
}

edge Contains {}

walker DeepAuditor {
    has big_files: list[str] = [];
    has steps: int = 0;

    can start with Root entry {
        visit : 0 : [-->];
    }

    can explore with Folder entry {
        self.steps += 1;
        print(f"{'  ' * (self.steps - 1)}enter {here.name}/");

        # Insert at FRONT of the queue: finish this subtree before
        # any sibling queued earlier gets its turn
        visit : 0 : [->:Contains:->];
        self.steps -= 1;
    }

    can measure with FileNode entry {
        mark = " <-- LARGE" if here.kb > 100 else "";
        print(f"file {here.name} ({here.kb} KB){mark}");
        if here.kb > 100 {
            self.big_files.append(f"{here.name} ({here.kb} KB)");
        }
    }

    can finish with Root exit {
        print("-- Oversized files --");
        for f in self.big_files {
            print(f);
        }
    }
}

with entry {
    project = Folder(name="project");
    src = Folder(name="src");
    assets = Folder(name="assets");

    main_py = FileNode(name="main.py", kb=12);
    engine_py = FileNode(name="engine.py", kb=240);
    logo_png = FileNode(name="logo.png", kb=310);
    readme_md = FileNode(name="README.md", kb=4);

    root ++> project;
    project +>: Contains() :+> src;
    project +>: Contains() :+> assets;
    project +>: Contains() :+> readme_md;
    src +>: Contains() :+> main_py;
    src +>: Contains() :+> engine_py;
    assets +>: Contains() :+> logo_png;

    root spawn DeepAuditor();
}
