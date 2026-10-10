"""Garage operations over the level graph."""

import from models { Level, Spot, Car, Contains, Occupied, SpotKind, kind_named, fee_for }
import from patrol { SpotFinder, LocateCar }

def find_level(number: int) -> Level | None;
def locate(plate: str) -> LocateCar;
def add_spot(code: str, level: int, kind: str) -> bool;
def park(plate: str, at: int, wants_ev: bool) -> str;
def where(plate: str) -> str;
def leave(plate: str, at: int) -> int;
def level_free(level: int) -> int;
def takings(level: int) -> int;
