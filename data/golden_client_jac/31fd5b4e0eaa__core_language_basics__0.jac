"""14-gram decontamination of holdout candidates against the training set.

Builds the set of 14-token shingles over all training Python (comment-stripped,
whitespace-tokenized) and flags any candidate whose shingles overlap the
training set above a threshold. This is the non-negotiable ordering guard: the
eval holdout must share no near-duplicate task with anything trained on.
"""

import json;
import from dedup { code_tokens }
import from pathlib { Path }
import from typing { Any }


def extract_python(rec: dict) -> str {
    msgs: list = list(rec["messages"]);
    user: dict = dict(msgs[0]);
    content: str = str(user["content"]);
    if "
