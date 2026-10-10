"""Supper club RSVPs: guests answer yes / no / maybe per event, yes answers may bring plus-ones, events may cap seats.

Event and Guest nodes hang off root; each answer is one Rsvp edge Guest -> Event.
Bodies live in rsvp.impl.jac.
"""

enum Answer {
    YES = "yes",
    NO = "no",
    MAYBE = "maybe"
}

node Event {
    has name: str;
    has capacity: int = 0;
}

node Guest {
    has key: str;
    has display: str;
}

edge Rsvp: Guest --> Event {
    has answer: Answer;
    has plus_ones: int = 0;
}

"""Spawned on root: validate and record (or replace) one guest's answer."""
walker Respond {
    has event: str;
    has guest: str;
    has answer: Answer;
    has plus_ones: int;
    has result: str = "";

    can record with Root entry;
}

"""Spawned on an Event: seats taken by yes answers (optionally ignoring one guest) and names per answer."""
walker Roster {
    has ignore: str = "";
    has seats: int = 0;
    has yes: list[str] = [];
    has no: list[str] = [];
    has maybe: list[str] = [];

    can count with Event entry;
}

"""Spawned on a Guest: events answered yes or maybe."""
walker Agenda {
    has lines: list[str] = [];

    can collect with Guest entry;
}

def parse_answer(answer: str) -> Answer | None;
def find_event(name: str) -> Event | None;
def find_guest(name: str) -> Guest | None;
def event_node(name: str) -> Event;
def rsvp(event: str, guest: str, answer: str, plus_ones: int = 0) -> str;
def set_capacity(event: str, seats: int) -> bool;
def headcount(event: str) -> int;
def guests(event: str, answer: str) -> list[str];
def agenda(guest: str) -> list[str];
def cancel(event: str, guest: str) -> bool;
