import os


def location(file_path: str, line: int, start_character: int, end_character: int) -> dict:
    """Build an LSP ``Location`` for a range within a file."""
    return {
        'uri': 'file://' + os.path.abspath(file_path),
        'range': {
            'start': {'line': line, 'character': start_character},
            'end': {'line': line, 'character': end_character},
        },
    }
