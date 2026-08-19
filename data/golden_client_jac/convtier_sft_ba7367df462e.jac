obj Version {
    has major: int = 0;
    has minor: int = 0;
    has patch: int = 0;

    def is_stable -> bool {
        return self.major >= 1;
    }

    def tag -> str {
        kind = "stable" if self.is_stable() else "preview";
        return f"{self.major}.{self.minor}.{self.patch} ({kind})";
    }
}

def from_string(s: str) -> Version {
    parts = s.split(".");
    return Version(major=int(parts[0]), minor=int(parts[1]), patch=int(parts[2]));
}

def parse_semver(s: str) -> str {
    return from_string(s).tag();
}

with entry {
    print(parse_semver('1.4.2'));
}
