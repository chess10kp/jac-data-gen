"""Config include-tree with cascade removal of inherited sections.

Config sections may pull in other sections via ``includes``; a base
section can be included by many sections. ``remove_section`` destroys the
requested section plus every base it pulls in EXCLUSIVELY; a base still
included by some surviving section is only detached. Every removed
section's resolved parameter map is snapshotted (own params win over
inherited ones) so callers can diff against live state afterwards.
Unknown include names are tolerated silently.
"""
class Section {
    has name: str;
    has params: dict[str, str];
    has includes: list[str] = [];
    has included_by: int = 0;
    def init(self: Section, name: str) -> object {
        self.name = name;
        self.params = {};
        self.includes = [];
        self.included_by = 0;
    }
}
class ConfigStore {
    has sections: dict[str, Section];
    def init(self: ConfigStore) -> object {
        self.sections = {};
    }
    def add(self: ConfigStore, name: str, params: dict[str, str] | None = None) -> object {
        sec = Section(name);
        sec.params = `dict((params or {}));
        self.sections[name] = sec;
        return sec;
    }
    def `include(self: ConfigStore, name: str, base_name: str) -> object {
        if ((name not in self.sections) or (base_name not in self.sections)) {
            return False;
        }
        self.sections[name].includes.append(base_name);
        self.sections[base_name].included_by += 1;
        return True;
    }
    def _collect(self: ConfigStore, name: str, doomed: list[Section], spared: list[Section]) -> object {
        if ((name in doomed) or (name in spared)) {
            return;
        }
        if (name not in self.sections) {
            return;
        }
        sec = self.sections[name];
        if (sec.included_by > 1) {
            spared.append(sec);
            return;
        }
        doomed.append(sec);
        for base in sec.includes {
            self._collect(base, doomed, spared);
        }
    }
    def resolve(self: ConfigStore, name: str) -> dict[str, str] | None {
        sec = self.sections.get(name);
        if (sec is None) {
            return None;
        }
        merged = {};
        for base_name in sec.includes {
            base_map = self.resolve(base_name);
            if base_map {
                merged.update(base_map);
            }
        }
        merged.update(sec.params);
        return merged;
    }
    def remove_section(self: ConfigStore, name: str) -> object {
        if (name not in self.sections) {
            return {};
        }
        snapshots = {};
        def snapshot_of(sec: Section) -> object {
            merged = {};
            for base_name in sec.includes {
                if (base_name in self.sections) {
                    merged.update(self.sections[base_name].params);
                }
            }
            merged.update(sec.params);
            snapshots[sec.name] = merged;
        }
        (doomed, spared) = ([], []);
        self._collect(name, doomed, spared);
        for dead in doomed {
            snapshot_of(dead);
            for base_name in dead.includes {
                if (base_name in self.sections) {
                    self.sections[base_name].included_by -= 1;
                }
            }
            delete(self.sections[dead.name],);
        }
        for sec in self.sections.values() {
            sec.includes[:] = [
                b
                for b in sec.includes
                if (b in self.sections)
            ];
        }
        return snapshots;
    }

    def live_sections(self: ConfigStore) -> object {
        return sorted(self.sections.keys());
    }
    def included_by_count(self: ConfigStore, name: str) -> object {
        sec = self.sections.get(name);
        return sec.included_by if sec else None;
    }
}

