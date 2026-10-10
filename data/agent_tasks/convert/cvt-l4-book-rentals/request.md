Our book-rental backend (`python/src/`) is FastAPI + Beanie with a repository/service layer per module (Book, Person, BookRental). We're moving it to Jac — please port the data + service logic to `rentals.jac`.

Graph model: `Book` (`title`, `description`, `author`, `isbn`, `genre`, `available_copies`, `total_copies`) and `Person` (`name`, `age`, `email`, `phone`, `address`) nodes on `root`; a `Rental` node (`rental_date`, `due_date`, `return_date`, `status` = "active" / "returned" / "overdue") hanging off the person via a `Rents` edge and pointing at its book via a `RentalOf` edge — no more string `book_id`/`person_id` fields. Dates are ISO strings.

Walkers on `root` (mirroring the service methods):
- `create_book(title, description, author, isbn=None, genre=None, available_copies=0, total_copies=0)` — reject `available_copies > total_copies` (or negatives) with a 422; `get_book(book_id)`, `get_available_books()`, `check_availability(book_id)` (bool).
- `create_person(name, age, email, phone=None, address=None)`, `get_person(person_id)`.
- `create_rental(book_id, person_id, due_date)` — same checks and messages as `BookRentalService.create_rental` (404 for a missing book, 409 `Book '<title>' is not available for rental`, 404 for a missing person), then one copy fewer available.
- `get_rental(rental_id)` — rental dict plus `book_title`, `person_name`, `person_email`.
- `get_all_rentals(skip=0, limit=100)`, `return_book(rental_id)` (sets `return_date`, status "returned", gives the copy back).
- `check_overdue(now)` — what `check_and_send_notifications` does: every *active* rental with `due_date < now` becomes "overdue"; instead of publishing to RabbitMQ, report the list of message dicts (`type`="overdue", `rental_id`, `book_title`, `person_name`, `person_email`, `due_date`, `rental_date`).

Book/person/rental dicts use the same keys as the response DTOs, with `id` = node `jid` (rentals carry `book_id` and `person_id` as jids too). Errors are reported as `{"status": <code>, "detail": "<message as in the Python>"}`. Please keep `jac check` clean.
