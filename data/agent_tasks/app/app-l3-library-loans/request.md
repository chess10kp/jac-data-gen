Our neighborhood has a tiny lending library (a shelf in the community center) and I want a command-line tool for it in Jac. This folder is a fresh `jac create` CLI project.

Data should live on the Jac graph under `root` and persist between runs:
- `Book` nodes (isbn, title, number of copies we own)
- `Member` nodes, created automatically the first time someone borrows
- a `Loan` edge from member to book carrying the due date

Loans are 14 days. A book is available if copies minus active loans > 0. One person can't borrow two copies of the same isbn at once.

Walkers I want in `main.jac` (names and fields exactly like this, so I can script against them):

| walker | fields | reports |
|---|---|---|
| `AddBook` | `isbn: str, title: str, copies: int` | the book |
| `Checkout` | `member: str, isbn: str, date: str` | a dict with `ok` (bool) and, when ok, `due` (ISO date) |
| `ReturnBook` | `member: str, isbn: str` | a dict with `ok` (bool) |
| `Available` | `isbn: str` | int copies available right now |
| `Overdue` | `date: str` | list of dicts `{member, isbn, due}` for loans whose due date is before `date`, sorted by due date then member |

And the CLI on top (`jac run main.jac ...`):

```
add-book <isbn> <copies> <title words...>
checkout <member> <isbn> <date>     -> prints "due <date>" or "unavailable"
return <member> <isbn>              -> prints "returned" or "no such loan"
available <isbn>                    -> prints the number
overdue <date>                      -> one line per loan "<member> <isbn> <due>", or "none overdue"
```
