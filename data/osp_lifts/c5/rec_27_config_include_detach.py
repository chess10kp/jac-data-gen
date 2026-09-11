"""Config include-tree with cascade removal of inherited sections.

Config sections may pull in other sections via ``includes``; a base
section can be included by many sections. ``remove_section`` destroys the
requested section plus every base it pulls in EXCLUSIVELY; a base still
included by some surviving section is only detached. Every removed
section's resolved parameter map is snapshotted (own params win over
inherited ones) so callers can diff against live state afterwards.
Unknown include names are tolerated silently.
"""


class Section:
    def __init__(self, name):
        self.name = name
        self.params = {}        # own parameters
        self.includes = []      # names of base sections (may be shared)
        self.included_by = 0    # live sections including this one


class ConfigStore:
    def __init__(self):
        self.sections = {}      # name -> Section

    def add(self, name, params=None):
        sec = Section(name)
        sec.params = dict(params or {})
        self.sections[name] = sec
        return sec

    def include(self, name, base_name):
        """Make *name* inherit from *base_name*; unknown refs tolerated."""
        if name not in self.sections or base_name not in self.sections:
            return False
        self.sections[name].includes.append(base_name)
        self.sections[base_name].included_by += 1
        return True

    def _collect(self, name, doomed, spared):
        """Recursive descent over includes, once-only per name."""
        if name in doomed or name in spared:
            return
        if name not in self.sections:
            return              # stale include reference tolerated
        sec = self.sections[name]
        if sec.included_by > 1:
            spared.append(sec)  # someone else still inherits from this
            return
        doomed.append(sec)
        for base in sec.includes:
            self._collect(base, doomed, spared)

    def resolve(self, name):
        """Merge params along the include chain; own params win."""
        sec = self.sections.get(name)
        if sec is None:
            return None
        merged = {}
        for base_name in sec.includes:
            base_map = self.resolve(base_name)
            if base_map:
                merged.update(base_map)
        merged.update(sec.params)
        return merged

    def remove_section(self, name):
        """Remove *name* + exclusive bases; returns removed-name snapshots.

        Shared bases are detached, not destroyed. Unknown names report {}.
        """
        if name not in self.sections:
            return {}
        snapshots = {}

        def snapshot_of(sec):
            merged = {}
            for base_name in sec.includes:
                if base_name in self.sections:
                    merged.update(self.sections[base_name].params)
            merged.update(sec.params)
            snapshots[sec.name] = merged

        doomed, spared = [], []
        self._collect(name, doomed, spared)
        for dead in doomed:
            snapshot_of(dead)
            for base_name in dead.includes:
                if base_name in self.sections:
                    self.sections[base_name].included_by -= 1
            del self.sections[dead.name]
        # sweeper pass: drop stale include entries left anywhere
        for sec in self.sections.values():
            sec.includes[:] = [
                b for b in sec.includes if b in self.sections
            ]
        return snapshots

    def live_sections(self):
        return sorted(self.sections.keys())

    def included_by_count(self, name):
        sec = self.sections.get(name)
        return sec.included_by if sec else None
