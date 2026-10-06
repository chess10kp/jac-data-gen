import sys;
import json;
import from urllib.parse { quote_plus }

glob DEFAULT_URL: str = "https://www.google.com";
glob SEARCH_URL: str = "https://www.google.com/search?q=";

"""R: Encode text for URL query usage.
M: Trims and URL-encodes query content with quote_plus.
E: Empty input maps to empty output.
"""
def encode_query(raw: str) -> str {
    cleaned = raw.strip();
    if not cleaned {
        return "";
    }
    return quote_plus(cleaned);
}

"""R: Normalize user omnibox text into a usable URL.
M: Uses explicit scheme, domain heuristic, then search fallback.
E: Empty text maps to DEFAULT_URL.
"""
def normalize_url(raw_input: str) -> str {
    cleaned = raw_input.strip();
    if not cleaned {
        return DEFAULT_URL;
    }

    lowered = cleaned.lower();
    if lowered.startswith("http://") or lowered.startswith("https://") {
        return cleaned;
    }

    looks_like_host = "." in cleaned and " " not in cleaned;
    if looks_like_host {
        return "https://" + cleaned;
    }

    return SEARCH_URL + encode_query(cleaned);
}

"""R: Build JSON payload consumed by Electron's main process.
M: Joins CLI args and returns normalized URL with original input.
E: No args yields default URL payload.
"""
def make_payload() -> dict {
    raw_input: str = "";
    if len(sys.argv) > 1 {
        raw_input = " ".join(sys.argv[1:]);
    }

    return {
        "input": raw_input,
        "url": normalize_url(raw_input)
    };
}

with entry {
    print(json.dumps(make_payload()));
}
