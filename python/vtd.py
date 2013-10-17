import collections
import datetime
import libvtd.node
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
    return '  @ ' + PrependParentProjectText(next_action, text) \
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


class Section(object):
    """A titled, ordered collection of nodes."""
    def __init__(self, title):
        self.title = title
        self.nodes = []
        self.node_at_line = {}

    def Lines(self, text_function):
        """A sequence of lines of text to display.

        Args:
            text_function: A function which accepts a Node and outputs the
                string to display for that Node.

        Returns:
            A sequence of strings representing the text for this section.
        """
        lines = ['= {} ='.format(self.title)]

        # last_priority is the priority of the previous Node we saw.  We use it
        # to insert a blank line between sections of different priority.
        last_priority = -1

        for node in self.nodes:
            if last_priority != -1 and last_priority != node.priority:
                lines.append('')
            last_priority = node.priority
            text_lines = text_function(node).split('\n')
            for text_line in text_lines:
                lines.append(text_line)
                self.node_at_line[len(lines) - 1] = node
        return lines

    def NodeAt(self, num):
        """Return the Node object at a given line.

        Args:
            num: The line number relative to the start of this section.
                (Title is '0'.)

        Returns:
            The Node object corresponding to the given line.
        """
        try:
            return self.node_at_line[num]
        except KeyError:
            return None


class SectionedDisplay(object):
    """Display text which is broken up into sections.

    Can give a list of lines of text, and can associate lines of text with
    Nodes.
    """
    def __init__(self):
        self.sections = []

    def Lines(self, text_function):
        """A sequence of lines of text to display.

        Args:
            text_function: A function which accepts a Node and outputs the
                string to display for that Node.

        Returns:
            A sequence of strings representing the text for all sections.
        """
        lines = []
        self.first_line = []
        for section in self.sections:
            lines.append('')
            self.first_line.append(len(lines) - 1)
            lines.extend(section.Lines(text_function))
        return lines[1:]

    def NodeAt(self, num):
        """Return the Node object at a given line.

        Args:
            num: The line number relative to the start of these sections.
                (Title of first section is '0'.)

        Returns:
            The Node object corresponding to the given line.
        """
        indexed_lines = [x for x in enumerate(self.first_line)]
        for index, first_line in reversed(indexed_lines):
            if first_line <= num:
                section = self.sections[index]
                node_index = num - first_line
                return section.NodeAt(node_index)
        return None


def MakeSectionedActions(actions):
    """Store an updated NextActions list in next_action_sections variable."""
    global next_action_sections

    # Categorize into sections ("late", "due", "ready", ...).
    categorized_actions = collections.defaultdict(list)
    now = datetime.datetime.now()
    for action in actions:
        categorized_actions[action.DateState(now)].append(action)

    # Sorter based on [priority (increasing), due date (increasing)]
    max_date = datetime.datetime(datetime.MAXYEAR, 12, 31, 23, 59, 59)
    date_key = lambda x: x.due_date if x.due_date else max_date
    priority_key = lambda x: -1 if x.priority is None else x.priority
    key = lambda x: (priority_key(x), date_key(x))

    # Make a section for each category.
    next_action_sections = SectionedDisplay()
    types = categorized_actions.keys()
    types.sort(reverse=True)
    for type in types:
        section = Section('{} ({})'.format(
            libvtd.node.DateStates[type].title(),
            len(categorized_actions[type])))
        categorized_actions[type].sort(key=key)
        section.nodes.extend(categorized_actions[type])
        next_action_sections.sections.append(section)
