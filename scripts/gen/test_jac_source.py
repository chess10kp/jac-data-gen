import unittest

from jac_source import strip_top_level_with_entry


class StripTopLevelWithEntryTests(unittest.TestCase):
    def test_strips_nested_entry_and_preserves_lines(self) -> None:
        source = '''"""A docstring with { braces }"""
node Item {
    has name: str = "}";
}
with entry {
    if True {
        print("nested }");
    }
    # comment with { and }
}
'''
        stripped, changed = strip_top_level_with_entry(source)

        self.assertTrue(changed)
        self.assertIn("node Item", stripped)
        self.assertNotIn('print("nested }");', stripped)
        self.assertEqual(source.count("\n"), stripped.count("\n"))

    def test_ignores_braces_in_strings_and_docstrings(self) -> None:
        source = '''"""text with entry { not a block }"""
with entry {
    print("{ still inside entry }");
    print(f"value={1}");
}
'''
        stripped, changed = strip_top_level_with_entry(source)

        self.assertTrue(changed)
        self.assertNotIn("still inside entry", stripped)
        self.assertEqual(source.count("\n"), stripped.count("\n"))

    def test_ignores_abilities_and_main_only_entry(self) -> None:
        source = '''walker Demo {
    can with entry { print("ability"); }
}
with entry:__main__ { print("main only"); }
'''

        stripped, changed = strip_top_level_with_entry(source)

        self.assertFalse(changed)
        self.assertEqual(source, stripped)

    def test_ignores_comments(self) -> None:
        source = '# with entry { not a block }\nnode Item { has x: int = 1; }\n'

        stripped, changed = strip_top_level_with_entry(source)

        self.assertFalse(changed)
        self.assertEqual(source, stripped)

    def test_no_entry_returns_original(self) -> None:
        source = 'node Item { has x: int = 1; }\n'

        stripped, changed = strip_top_level_with_entry(source)

        self.assertFalse(changed)
        self.assertEqual(source, stripped)

    def test_malformed_entry_fails_closed(self) -> None:
        with self.assertRaises(ValueError):
            strip_top_level_with_entry("with entry { print(\"never closes\");\n")

    def test_multiple_entries_fail_closed(self) -> None:
        source = "with entry { print(1); }\nwith entry { print(2); }\n"

        with self.assertRaises(ValueError):
            strip_top_level_with_entry(source)


if __name__ == "__main__":
    unittest.main()
