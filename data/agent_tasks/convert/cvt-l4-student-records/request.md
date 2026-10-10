I've got a small FastAPI + Beanie (MongoDB) student-records service under `python/` — the model is in `python/models/student.py`, the async CRUD helpers in `python/database/database.py`, and the router in `python/routes/student.py`. I want to retire Mongo and keep the data in the Jac graph instead.

Please port the student part to `students.jac`:

- a `Student` node with `fullname`, `email`, `course_of_study`, `year` (int) and `gpa` (float), stored on `root`;
- one walker per database helper, same names, spawned on `root`:
  - `add_student(fullname, email, course_of_study, year, gpa)` — reports the new student as a dict with an `"id"` (the node's `jid`) plus all five fields. If the email isn't a plausible address (the Python model uses `EmailStr`), report `{"error": ...}` and store nothing.
  - `retrieve_students()` — reports one list of those student dicts.
  - `retrieve_student(id)` — reports the dict, or `None` if there's no such student.
  - `update_student_data(id, ...)` — every field optional; only the ones actually passed change (same as the `$set` of non-None values). Reports the updated dict, or `False` if the id is unknown.
  - `delete_student(id)` — reports `True` if it deleted something, else `False`.

Leave out the admin/auth stuff. Needs to pass `jac check`.
