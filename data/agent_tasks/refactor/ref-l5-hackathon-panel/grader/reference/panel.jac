"""Judging panel operations."""

import from models { Track, Team, Judge, Entered, Covers, Scored, Criterion, criterion_named }
import from rounds { Standings, Backlog }

def find_team(name: str) -> Team | None;
def find_judge(name: str) -> Judge | None;
def find_track(name: str) -> Track | None;
def register_team(name: str, track: str) -> bool;
def add_judge(name: str) -> bool;
def assign(judge: str, track: str) -> bool;
def score(judge: str, team: str, criterion: str, points: int) -> str;
def team_score(team: str) -> float;
def leaderboard(track: str) -> list[str];
def pending(judge: str) -> list[str];
