# Gym class booking backend

I run a small climbing gym and want a booking API for our classes (yoga, intro to bouldering, etc.). The repo is a fresh `jac create --kind service` project — please replace the sample guestbook code.

## Data

Classes and members should live on the Jac graph under `root` (persisting across requests): a node per class, a node per member, and a booking edge between them.

## Endpoints

All public, as `def:pub` functions (so `POST /function/<name>`):

| function | params | returns |
|---|---|---|
| `create_class` | `name: str`, `capacity: int` | the class view |
| `book_spot` | `class_id: str`, `member: str` | the class view after booking |
| `cancel_booking` | `class_id: str`, `member: str` | the class view after cancelling |
| `list_classes` | — | list of class views, sorted by name |
| `roster` | `class_id: str` | sorted list of member names booked in the class |

A **class view** is `{"id": <class id string>, "name": ..., "capacity": ..., "booked": <int>, "spots_left": <int>}`. Use the node's `jid` as the id.

## Rules / errors

When something is wrong, return `{"error": "<message>"}` instead of a view:
- capacity must be at least 1
- unknown class id
- booking a full class
- the same member booking the same class twice
- cancelling a booking that doesn't exist

Member names are case-sensitive.

Also add Jac tests covering the booking rules, and make sure the service starts with `jac start`.
