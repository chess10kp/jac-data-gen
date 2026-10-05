import from base64 { b64decode }
import from requests { get, post }
import from byllm.lib { Image }

def llm_predict_color_from_list(img: Image, PotentialColors: list) -> str by llm();

def:pub get_llm_color(frame_data: str, active_known_colors: list) -> str {
    print("Predicting color with LLM...");
    inImg = Image(frame_data);
    llm_predict_color = llm_predict_color_from_list(inImg, active_known_colors);
    print("LLM predicted color:", llm_predict_color);
    return llm_predict_color;
}

def parse_data_url(frame_data: str) -> tuple[str, bytes] {
    if not frame_data {
        return ("image/jpeg", b"");
    }
    parts = frame_data.split(",", 1);
    if len(parts) < 2 {
        return ("image/jpeg", b"");
    }
    header = parts[0];
    mime_type = "image/jpeg";
    if ";" in header and ":" in header {
        mime_type = header.split(":", 1)[1].split(";", 1)[0];
    }
    try {
        decoded = b64decode(parts[1]);
        return (mime_type, decoded);
    } except Exception {
        return (mime_type, b"");
    }
}


def safe_get(source: any, key: str, fallback: any) -> any {
    if source == None {
        return fallback;
    }
    try {
        value = source.get(key);
        if value == None {
            return fallback;
        }
        return value;
    } except Exception {
        return fallback;
    }
}


def normalize_items(payload: any) -> list {
    if payload == None {
        return [];
    }
    try {
        payload_type = type(payload);
        if payload_type == list {
            return payload;
        }
        if payload_type == dict {
            for key in ["items", "predictions", "results"] {
                value = safe_get(payload, key, []);
                if type(value) == list {
                    return value;
                }
            }
        }
    } except Exception {
    }
    return [];
}


def item_name(item: any) -> str {
    for key in ["name", "label", "class_name", "id", "part_num"] {
        value = safe_get(item, key, "");
        if value {
            return str(value);
        }
    }
    return "Unknown part";
}


def item_confidence(item: any) -> int {
    for key in ["score", "confidence", "probability"] {
        value = safe_get(item, key, None);
        if value != None {
            try {
                numeric = float(value);
                if numeric <= 1.0 {
                    numeric = numeric * 100.0;
                }
                return int(round(numeric));
            } except Exception {
            }
        }
    }
    return 0;
}


def item_notes(item: any) -> str {
    for key in ["description", "category", "part_num", "id"] {
        value = safe_get(item, key, "");
        if value {
            return str(value);
        }
    }
    return "Trained Brickognize classification result.";
}


def bricklink_part_id_from_url(url: str) -> str {
    if not url {
        return "";
    }
    if "?P=" in url {
        part_section = url.split("?P=", 1)[1];
        return part_section.split("&", 1)[0].strip();
    }
    if "?S=" in url {
        part_section = url.split("?S=", 1)[1];
        return part_section.split("&", 1)[0].strip();
    }
    return "";
}


def item_part_id(item: any) -> str {
    external_sites = safe_get(item, "external_sites", []);
    if type(external_sites) == list {
        for site in external_sites {
            site_name = str(safe_get(site, "name", "")).lower();
            site_url = str(safe_get(site, "url", ""));
            if site_name == "bricklink" and site_url {
                bricklink_part_id = bricklink_part_id_from_url(site_url);
                if bricklink_part_id {
                    return bricklink_part_id;
                }
            }
        }
    }

    for key in ["part_num", "item_no", "id", "part_id"] {
        value = safe_get(item, key, "");
        if value {
            return str(value);
        }
    }

    identifiers = safe_get(item, "identifiers", None);
    if type(identifiers) == dict {
        for key in ["bricklink", "bricklink_id", "part_num", "item_no", "id"] {
            value = safe_get(identifiers, key, "");
            if value {
                return str(value);
            }
        }
    }

    return "";
}


def item_bricklink_url(item: any, part_id: str) -> str {
    external_sites = safe_get(item, "external_sites", []);
    if type(external_sites) == list {
        for site in external_sites {
            site_name = str(safe_get(site, "name", "")).lower();
            site_url = str(safe_get(site, "url", ""));
            if site_name == "bricklink" and site_url {
                return site_url;
            }
        }
    }
    if part_id {
        return "https://www.bricklink.com/v2/catalog/catalogitem.page?P=" + part_id;
    }
    return "";
}


def strip_tags(text: str) -> str {
    cleaned = "";
    inside_tag = False;
    for ch in text {
        if ch == "<" {
            inside_tag = True;
        } elif ch == ">" {
            inside_tag = False;
        } elif not inside_tag {
            cleaned = cleaned + ch;
        }
    }
    cleaned = cleaned.replace("&nbsp;", " ");
    cleaned = cleaned.replace("&amp;", "&");
    cleaned = cleaned.replace("\n", " ");
    cleaned = cleaned.replace("\r", " ");
    cleaned = cleaned.replace("\t", " ");
    while "  " in cleaned {
        cleaned = cleaned.replace("  ", " ");
    }
    return cleaned.strip();
}


def parse_bricklink_known_colors(page_text: str) -> dict {
    if not page_text {
        return {"label": "Unknown", "items": [], "source": "BrickLink"};
    }

    marker = "Known Colors:";
    if marker not in page_text {
        marker = "Known Color:";
    }
    if marker not in page_text {
        return {"label": "Unknown", "items": [], "source": "BrickLink"};
    }

    section = page_text.split(marker, 1)[1];
    for stop in ["</td>", "</TD>", "Price Guide", "My Wanted List", "My Inventory", "Item Name:", "Years Released:", "Year Released:", "Weight:", "Item Dim", "Catalog Item Name:", "Appears In", "Item Consists Of"] {
        if stop in section {
            section = section.split(stop, 1)[0];
        }
    }

    colors = [];

    for anchor_piece in section.split("</a>") {
        if "<a " not in anchor_piece {
            continue;
        }
        if "colorID=" not in anchor_piece and "catalogItemIn.asp" not in anchor_piece {
            continue;
        }
        anchor_html = anchor_piece.split("<a ", 1)[1];
        if ">" not in anchor_html {
            continue;
        }
        color_name = strip_tags(anchor_html.split(">", 1)[1]).strip();
        if not color_name {
            continue;
        }
        lowered = color_name.lower();
        if ":" in color_name or "known color" in lowered or lowered in ["view", "details"] {
            continue;
        }
        if color_name not in colors {
            colors.append(color_name);
        }
    }

    if len(colors) == 0 {
        cleaned = strip_tags(section);
        if cleaned {
            normalized = cleaned.replace(" ,", ",").replace(", ", ",");
            normalized = normalized.replace(" / ", ",");
            normalized = normalized.replace("|", ",");
            normalized = normalized.replace(";", ",");
            normalized = normalized.replace("  ", " ");

            for piece in normalized.split(",") {
                color_name = piece.strip();
                if not color_name {
                    continue;
                }
                lowered = color_name.lower();
                if ":" in color_name or "known color" in lowered {
                    continue;
                }
                if color_name not in colors {
                    colors.append(color_name);
                }
            }
        }
    }

    if len(colors) == 0 {
        return {"label": "Unknown", "items": [], "source": "BrickLink"};
    }

    return {"label": ", ".join(colors), "items": colors, "source": "BrickLink"};
}


def parse_years_released(page_text: str) -> dict {
    if not page_text {
        return {"label": "Unknown", "start": "", "end": "", "source": "BrickLink"};
    }

    marker = "Years Released:";
    if marker not in page_text {
        marker = "Year Released:";
    }
    if marker not in page_text {
        return {"label": "Unknown", "start": "", "end": "", "source": "BrickLink"};
    }

    section = page_text.split(marker, 1)[1];
    for stop in ["Weight:", "Item Dim", "<br", "</td>"] {
        if stop in section {
            section = section.split(stop, 1)[0];
        }
    }
    section = strip_tags(section);

    year_tokens = [];
    current = "";
    for ch in section {
        if ch >= "0" and ch <= "9" {
            current = current + ch;
        } else {
            if len(current) == 4 {
                year_tokens.append(current);
            }
            current = "";
        }
    }
    if len(current) == 4 {
        year_tokens.append(current);
    }

    if len(year_tokens) >= 2 {
        start_year = year_tokens[0];
        end_year = year_tokens[1];
        return {"label": start_year + "–" + end_year, "start": start_year, "end": end_year, "source": "BrickLink"};
    }
    if len(year_tokens) == 1 {
        return {"label": year_tokens[0], "start": year_tokens[0], "end": year_tokens[0], "source": "BrickLink"};
    }
    return {"label": "Unknown", "start": "", "end": "", "source": "BrickLink"};
}


def fetch_bricklink_metadata(part_id: str, bricklink_url: str) -> dict {
    if not bricklink_url and not part_id {
        return {
            "years_released": {"label": "Unknown", "start": "", "end": "", "source": "BrickLink"},
            "known_colors": {"label": "Unknown", "items": [], "source": "BrickLink"},
        };
    }

    target_url = bricklink_url;
    if not target_url {
        target_url = "https://www.bricklink.com/v2/catalog/catalogitem.page?P=" + part_id;
    }

    try {
        response = get(
            target_url,
            headers={
                "user-agent": "Mozilla/5.0 (compatible; JacCoder BrickLink lookup)",
                "accept": "text/html,application/xhtml+xml",
            },
            timeout=20,
        );
    } except Exception as e {
        return {
            "years_released": {"label": "Unavailable", "start": "", "end": "", "source": "BrickLink", "error": "BrickLink lookup failed: " + str(e)},
            "known_colors": {"label": "Unavailable", "items": [], "source": "BrickLink", "error": "BrickLink lookup failed: " + str(e)},
        };
    }

    if response.status_code < 200 or response.status_code >= 300 {
        return {
            "years_released": {"label": "Unavailable", "start": "", "end": "", "source": "BrickLink", "error": "BrickLink returned status " + str(response.status_code)},
            "known_colors": {"label": "Unavailable", "items": [], "source": "BrickLink", "error": "BrickLink returned status " + str(response.status_code)},
        };
    }

    return {
        "years_released": parse_years_released(response.text),
        "known_colors": parse_bricklink_known_colors(response.text),
    };
}


def:pub recognize_lego_frame(frame_data: str) -> dict {
    parsed = parse_data_url(frame_data);
    mime_type = parsed[0];
    raw = parsed[1];
    if not raw {
        return {"success": False, "error": "No frame data received"};
    }

    extension = ".jpg";
    if mime_type == "image/png" {
        extension = ".png";
    }

    try {
        response = post(
            "https://api.brickognize.com/predict/",
            headers={"accept": "application/json"},
            files={"query_image": ("capture" + extension, raw, mime_type)},
            timeout=30,
        );
    } except Exception as e {
        return {"success": False, "error": "Brickognize request failed: " + str(e)};
    }

    if response.status_code < 200 or response.status_code >= 300 {
        return {"success": False, "error": "Brickognize returned status " + str(response.status_code)};
    }

    try {
        payload = response.json();
    } except Exception as e {
        return {"success": False, "error": "Brickognize response was not valid JSON: " + str(e)};
    }

    items = normalize_items(payload);
    best_name = "Unknown part";
    best_confidence_value = 0;
    best_notes = "Trained Brickognize classification result.";
    best_part_id = "";
    best_bricklink_url = "";

    if len(items) > 0 {
        first = items[0];
        best_name = item_name(first);
        best_confidence_value = item_confidence(first);
        best_notes = item_notes(first);
        best_part_id = item_part_id(first);
        best_bricklink_url = item_bricklink_url(first, best_part_id);
    } else {
        best_name = str(safe_get(payload, "name", "Unknown part"));
        best_confidence_value = item_confidence(payload);
        best_notes = item_notes(payload);
        best_part_id = item_part_id(payload);
        best_bricklink_url = item_bricklink_url(payload, best_part_id);
    }

    bricklink_metadata = fetch_bricklink_metadata(best_part_id, best_bricklink_url);
    years_released = safe_get(bricklink_metadata, "years_released", {"label": "Unknown", "start": "", "end": "", "source": "BrickLink"});
    known_colors = safe_get(bricklink_metadata, "known_colors", {"label": "Unknown", "items": [], "source": "BrickLink"});

    return {
        "success": True,
        "active_match": {
            "name": best_name,
            "confidence": str(best_confidence_value) + "%",
            "notes": best_notes,
            "part_id": best_part_id,
            "specific_part_number": best_part_id,
            "bricklink_url": best_bricklink_url,
            "years_released": years_released,
            "known_colors": known_colors,
        },
        "telemetry": {
            "provider": "Brickognize",
            "candidate_count": len(items),
            "mime_type": mime_type,
            "bytes": len(raw),
        },
        "raw": payload,
    };
}
