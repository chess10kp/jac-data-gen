# Capacity allocator

Write a single Jac module `solution.jac`.

Define two typed objects and one public function:

- `Request` — a typed object with a string `id` and an integer `count`.
- `AllocationResult` — a typed object with `accepted: list[str]`, `rejected: list[str]`, and `used: int`.
- `allocate_requests(requests: list[Request], capacity: int) -> AllocationResult`

## Behavior

`allocate_requests` receives requests **in input order** and a **non-negative**
`capacity`. Process each request in order and **accept** it only if all of:

1. no **earlier accepted** request in this call has the same `id`,
2. its `count` is strictly positive, and
3. it fits in the remaining capacity (`used + count <= capacity`).

Otherwise **reject** it. Rejecting a request must not consume capacity, and a
request that does not fit must **not** stop processing of later requests — a
smaller later request may still be accepted.

The duplicate rule keys off **accepted** IDs only: if an earlier occurrence of
an ID was rejected (invalid count or non-fitting), a later valid occurrence of
that same ID may still be accepted. An ID can be accepted at most once.

Return:

- `accepted`: the accepted IDs, in the order they were accepted,
- `rejected`: the rejected IDs, in the order they were rejected,
- `used`: the total capacity consumed by accepted requests.

Do **not** mutate the caller's `requests` list or the objects inside it.

Output only the `solution.jac` source in a single fenced ```jac block.
