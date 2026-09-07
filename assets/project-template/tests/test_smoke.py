from src.main import main


def test_template_entry_point() -> None:
    assert main() == 0
