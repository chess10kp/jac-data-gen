import type from _pytest.mark.structures { MarkDecorator }

""" Getting mark which works in various pytest versions """
def get_marker(func_item: object, mark: str) -> MarkDecorator | None {
    pytetstmark = [
        m
        for m in (getattr(func_item, 'pytestmark', None) or [])
        if m.name == mark
    ];
    if pytetstmark {
        return pytetstmark[0];
    }
}