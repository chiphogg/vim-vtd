import sys


def AddToSysPath(path):
    """Add path to sys.path, unless it's already there.

    Args:
        path: The path to add.
    """
    if path not in sys.path:
        sys.path.append(path)
