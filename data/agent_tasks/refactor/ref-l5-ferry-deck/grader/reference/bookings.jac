"""Reservation desk operations over the ferry graph."""

import from models { Sailing, Booking, Holds, Vehicle, vehicle_named }
import from sweeps { LocateBooking, DayCount }

def find_sailing(code: str) -> Sailing | None;
def locate(ref: str) -> LocateBooking;
def add_sailing(code: str, day: int, lanes: int, seats: int) -> bool;
def book(sailing: str, ref: str, vehicle: str, passengers: int) -> str;
def cancel(ref: str) -> bool;
def move(ref: str, to_sailing: str) -> str;
def manifest(sailing: str) -> list[str];
def free_space(sailing: str) -> list[int];
def day_passengers(day: int) -> int;
