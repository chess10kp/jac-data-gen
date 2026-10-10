"""Front-desk operations over the kennel graph."""

import from models { Run, Stay, Hosts, Size, size_named, size_rank }
import from rounds { PickRun, NightList, Departure, Billing }

def find_run(code: str) -> Run | None;
def add_run(code: str, size: str, nightly: int) -> bool;
def reprice(code: str, nightly: int) -> bool;
def book(dog: str, size: str, start: int, nights: int) -> str;
def check_out(dog: str) -> int;
def occupancy(night: int) -> list[str];
def free_runs(size: str, start: int, nights: int) -> int;
def bill(dog: str) -> int;
