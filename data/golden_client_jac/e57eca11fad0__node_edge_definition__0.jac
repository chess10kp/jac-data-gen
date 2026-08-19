node Course {
    has code: str;
    has name: str;
    has credits: int;
}

edge Prerequisite {
    has required: bool = True;
}

walker CanTake {
    has completed: list;
    has can_take: bool = True;

    can start with Root entry {
        visit [-->];
    }

    can check with Course entry {
        # Check prerequisites
        prereqs = [here <-:Prerequisite:<-];

        for prereq in prereqs {
            if prereq.code not in self.completed {
                print(f"Missing prerequisite: {prereq.code} - {prereq.name}");
                self.can_take = False;
            }
        }
    }
}

walker FindPath {
    has target_code: str;
    has path: list = [];
    has visited: set = set();

    can start with Root entry {
        visit [-->];
    }

    can explore with Course entry {
        if here.code in self.visited {
            return;
        }

        self.visited.add(here.code);
        self.path.append(here.code);

        if here.code == self.target_code {
            print(f"Course path: {' -> '.join(self.path)}");
            disengage;
        }

        visit [here ->:Prerequisite:->];
        self.path.pop();
    }
}

with entry {
    # Create courses
    cs101 = Course(code="CS101", name="Intro to Programming", credits=3);
    cs201 = Course(code="CS201", name="Data Structures", credits=4);
    cs301 = Course(code="CS301", name="Algorithms", credits=4);
    math151 = Course(code="MATH151", name="Calculus I", credits=4);

    # Define prerequisites
    cs201 +>:Prerequisite:+> cs101;
    cs301 +>:Prerequisite:+> cs201;
    cs301 +>:Prerequisite:+> math151;

    # Check if student can take CS301
    root ++> cs301;
    checker = CanTake(completed=["CS101", "CS201", "MATH151"]);
    cs301 spawn checker;

    if checker.can_take {
        print("You can take CS301!");
    } else {
        print("Complete prerequisites first");
    }
}
