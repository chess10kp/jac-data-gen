"""Arcade high scores: Game nodes holding one Best node per player."""

import time;

node Game {
    has name: str;
}

node Best {
    has player: str;
    has score: int;
    has seq: float = 0.0;
}

def rank_key(b: Best) -> tuple[int, float] {
    return (-b.score, b.seq);
}

def board(g: Game) -> list[dict[str, any]] {
    entries = sorted([b for b in [g -->[?:Best]]], key=rank_key);
    return [{"player": b.player, "score": b.score} for b in entries[:5]];
}

walker:pub submit_score {
    has game: str;
    has player: str;
    has score: int;

    can submit with Root entry {
        if self.score < 0 {
            report {"error": "invalid score"};
            return;
        }
        games = [g for g in [here -->[?:Game]] if g.name == self.game];
        g = games[0] if games else here ++> Game(name=self.game);
        tag = self.player.strip().upper()[:3];
        mine = [b for b in [g -->[?:Best]] if b.player == tag];
        if not mine {
            g ++> Best(player=tag, score=self.score, seq=time.time());
        } elif self.score > mine[0].score {
            mine[0].score = self.score;
            mine[0].seq = time.time();
        }
        report board(g);
    }
}
