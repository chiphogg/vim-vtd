import datetime
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
    text = PriorityDecoratedText(next_action)
    return '@ ' + PrependParentProjectText(next_action, text) \
        + DueDateIndication(next_action)


def PriorityDecoratedText(node):
    """node.text, appropriately decorated according to its priority.

    Args:
        node: A libvtd.node.Node object.

    Returns:
        node.text, wrapped in '[P#:', ':P#]' (where '#' is the priority level,
        or else 'X' if no valid priority is set).
    """
    allowed_priorities = [x for x in range(5)]  # [0, ..., 4].
    priority = node.priority if node.priority in allowed_priorities else 'X'
    return '[P{0}:{1}:P{0}]'.format(priority, node.text)


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


def DueDateIndication(node):
    """Indicates how node's due date compares to the current time.

    Args:
        node: A libvtd.node.Node object.

    Returns:
        Human-readable due date indication -- such as "Late 3 days", or
        "Due in 50 minutes" -- wrapped in parenthesis and prepended by ' '.
        If no due date, the empty string is returned.
    """
    if not node.due_date:
        return ''
    time_diff_secs = (datetime.datetime.now() - node.due_date).total_seconds()
    fmt = ' ({})'.format('Due in {}' if time_diff_secs < 0 else 'Late {}')
    return fmt.format(PrettyRelativeTime(time_diff_secs))


def PrettyRelativeTime(time_diff_secs):
    """Human-readable representation of a time difference.

    E.g., '3 days', or '75 minutes'.

    Args:
        time_diff_secs: The time difference in seconds.  Note that the absolute
        value is used.

    Returns:
        A human-readable representation of time_diff_secs.  Prefers smaller
        numbers (hence, bigger time units), and goes to the next time unit when
        we have at least 2 of them: so, we would have "119 minutes",
        but "2 hours" instead of "120 minutes".
    """
    # Each tuple in the sequence gives the name of a unit, and the number of
    # previous units which go into it.
    weeks_per_month = 365.242 / 12 / 7
    intervals = [('minute', 60), ('hour', 60), ('day', 24), ('week', 7),
                 ('month', weeks_per_month), ('year', 12)]

    unit, number = 'second', abs(time_diff_secs)
    for new_unit, ratio in intervals:
        new_number = float(number) / ratio
        # If the new number is too small, don't go to the next unit.
        if new_number < 2:
            break
        unit, number = new_unit, new_number
    return Quantity(number, unit)


def Quantity(number, singular, plural=None):
    """A quantity, with the correctly-pluralized form of a word.

    E.g., '3 hours', or '1 minute'.

    Args:
        number: The number used to decide whether to pluralize.  (Basically: we
            will, unless it's 1.)
        singular: The singular form of the term.
        plural: The plural form of the term (default: singular + 's').

    Returns:
        A string starting with number, and ending with the appropriate form of
        the term (i.e., singular if number is 1, plural otherwise).
    """
    plural = plural if plural else singular + 's'
    number = int(number)
    return '{} {}'.format(number, singular if number == 1 else plural)
