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
    can check with Course entry {
        prereqs = [here <-:Prerequisite:<-];
        for prereq in prereqs {
            if prereq.code not in self.completed {
                print(f"Missing prerequisite: {prereq.code} - {prereq.name}");
                self.can_take = False;
            }
        }
    }
}
