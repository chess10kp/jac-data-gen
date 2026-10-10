"""Student records: the Beanie `Student` collection becomes `Student` nodes on root,
and each async CRUD helper from database/database.py becomes a walker."""

import re;

node Student {
    has fullname: str;
    has email: str;
    has course_of_study: str;
    has year: int;
    has gpa: float;

    def view -> dict[str, any] {
        return {"id": jid(self), "fullname": self.fullname, "email": self.email,
                "course_of_study": self.course_of_study, "year": self.year, "gpa": self.gpa};
    }
}

"""Look a student up by its id among root's students (Student.get(id))."""
def find_student(id: str) -> Student | None {
    for s in [root -->[?:Student]] {
        if jid(s) == id {
            return s;
        }
    }
    return None;
}

def valid_email(email: str) -> bool {
    return re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email) is not None;
}

walker add_student {
    has fullname: str;
    has email: str;
    has course_of_study: str;
    has year: int;
    has gpa: float;

    can create with Root entry {
        if not valid_email(self.email) {
            report {"error": "invalid email"};
            return;
        }
        s = here ++> Student(fullname=self.fullname, email=self.email,
                             course_of_study=self.course_of_study, year=self.year, gpa=self.gpa);
        report s.view();
    }
}

walker retrieve_students {
    can list_all with Root entry {
        report [s.view() for s in [-->[?:Student]]];
    }
}

walker retrieve_student {
    has id: str;

    can fetch with Root entry {
        s = find_student(self.id);
        report s.view() if s else None;
    }
}

walker update_student_data {
    has id: str;
    has fullname: str | None = None;
    has email: str | None = None;
    has course_of_study: str | None = None;
    has year: int | None = None;
    has gpa: float | None = None;

    can patch with Root entry {
        s = find_student(self.id);
        if s is None {
            report False;
            return;
        }
        # only fields that were supplied (non-None) are $set
        if self.fullname is not None {
            s.fullname = self.fullname;
        }
        if self.email is not None {
            s.email = self.email;
        }
        if self.course_of_study is not None {
            s.course_of_study = self.course_of_study;
        }
        if self.year is not None {
            s.year = self.year;
        }
        if self.gpa is not None {
            s.gpa = self.gpa;
        }
        report s.view();
    }
}

walker delete_student {
    has id: str;

    can remove with Root entry {
        s = find_student(self.id);
        if s is None {
            report False;
            return;
        }
        del s;
        report True;
    }
}
