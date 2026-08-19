obj Settings {
    has theme: str = "light";
    has font_size: int = 12;
    has autosave: bool = True;

    def merge(overrides: dict) -> None {
        if "theme" in overrides {
            self.theme = overrides["theme"];
        }
        if "font_size" in overrides {
            self.font_size = overrides["font_size"];
        }
        if "autosave" in overrides {
            self.autosave = overrides["autosave"];
        }
    }

    def summary -> str {
        return f"theme={self.theme} size={self.font_size} autosave={self.autosave}";
    }
}

def apply_settings(overrides: dict) -> str {
    s = Settings();
    s.merge(overrides);
    return s.summary();
}

with entry {
    print(apply_settings({'theme': 'dark'}));
}
