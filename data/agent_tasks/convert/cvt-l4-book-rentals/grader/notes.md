# cvt-l4-book-rentals
Source FelipeFlamarini/DdAD-books (MIT) @a45daab. FARM L4 with a layered (repository/service)
source: string foreign keys become a Person -[Rents]-> Rental -[RentalOf]-> Book path; the RabbitMQ
publish becomes a reported list. Negatives: no copy decrement, sold-out not checked, return doesn't
restore, returned rentals swept as overdue, copy validation off.
