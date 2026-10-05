"""Mesh helpers: cross-reference extraction for references / modifies edges."""

import re;


def extract_section_refs(text: str) -> list {
    refs = [];
    for m in re.findall(r"(?i)section\s+(\d+(?:\.\d+)*)", text) {
        refs.append(str(m));
    }
    for m in re.findall(r"\u00a7\s*(\d+(?:\.\d+)*)", text) {
        refs.append(str(m));
    }
    return refs;
}


def extract_modifies_target(text: str) -> list {
    refs = [];
    for m in re.findall(r"(?i)notwithstanding\s+section\s+(\d+(?:\.\d+)*)", text) {
        refs.append(str(m));
    }
    for m in re.findall(r"(?i)subject to\s+section\s+(\d+(?:\.\d+)*)", text) {
        refs.append(str(m));
    }
    return refs;
}


def split_contract_fallback(text: str) -> list {
    chunks = [];
    ::py::
    import re
    text = (text or "").strip()
    rows = []
    if text:
        parts = re.split(r"\n(?=\d+(?:\.\d+)?\s)", text)
        for i, part in enumerate(parts):
            part = part.strip()
            if not part:
                continue
            m = re.match(r"^(\d+(?:\.\d+)?)\s*(.*)$", part, re.S)
            if m:
                cid = m.group(1)
                rest = (m.group(2) or "").strip()
                section = rest.split("\n")[0][:120] if rest else ""
                rows.append({
                    "clause_id": cid,
                    "text": part,
                    "section": section,
                    "page_number": 1,
                    "clause_type": "obligation",
                })
            elif i == 0 and len(parts) > 1:
                rows.append({
                    "clause_id": "0",
                    "text": part,
                    "section": "Preamble",
                    "page_number": 1,
                    "clause_type": "definition",
                })
    chunks = rows
    ::py::
    return chunks;
}
