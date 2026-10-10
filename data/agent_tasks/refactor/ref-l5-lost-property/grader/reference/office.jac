"""Lost-property desk operations."""

import from models { Station, Item, Claimant, Holds, ClaimedBy, Category, category_named }
import from sweeps { Search, Expiry }

def station_named(name: str) -> Station;
def find_item(tag: str) -> Item | None;
def log_item(category: str, color: str, day: int, station: str) -> str;
def search(category: str, color: str, since_day: int) -> list[str];
def claim(tag: str, name: str, day: int) -> str;
def claims_of(name: str) -> list[str];
def transfer(src: str, dst: str) -> int;
def held_at(station: str) -> list[str];
def expire(today: int, keep_days: int) -> list[str];
