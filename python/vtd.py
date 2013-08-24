import libvtd.trusted_system


def UpdateTrustedSystem(file_name):
    """Make sure the TrustedSystem object is up to date."""
    global my_system
    if 'my_system' not in globals():
        my_system = libvtd.trusted_system.TrustedSystem()
        my_system.AddFile(file_name)
    my_system.Refresh()


def NextActionDisplayText(next_action):
    """The text to display in the NextActions view.

    Args:
        next_action: A NextAction object.

    Returns:
        The text to display for it.  Includes the projects (if any), followed
        by the NextAction text, followed by an indication of how the current
        time compares to the due date (if any).
    """
    return PrependParentProjectText(next_action, next_action.text)


def PrependParentProjectText(node, text):
    """Prepend text from the parent projects for context.

    Args:
        node: A libvtd.node.Node object.
        text: The text to which we prepend.

    Returns:
        A string of the form:
            <Grandparent Project text> :: <Parent Project text> :: text
    """
    if isinstance(node.parent, libvtd.node.Project):
        return PrependParentProjectText(node.parent,
                                        node.parent.text + ' :: ' + text)
    return text
