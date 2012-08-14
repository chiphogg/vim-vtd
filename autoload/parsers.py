# ============================================================================
# File:        autoload/parsers.py
# Description: Parsers for VTD lists
# Maintainer:  Charles R. Hogg III <charles.r.hogg@gmail.com>
# License:     Distributed under the same terms as vim itself
# ============================================================================

import vim
import re
import os
from datetime import datetime, timedelta
import string

try:
    AUTOLOAD_PARSERS_PY
except NameError:
    AUTOLOAD_PARSERS_PY = True;

def seconds_diff(a, b):
    """The number of seconds which a occurs after b, neglecting microseconds

    Arguments:
    a - A datetime object
    b - Another datetime object
    """
    dt = a - b
    return dt.seconds + dt.days * 24 * 3600

def pluralize(count, string, string_plural=None):
    """Print 'count string(s)' with proper pluralization

    Arguments:
    count - some integer number
    string - The singular form of the kind of thing we're counting
    string_plural - The plural form (defaults to adding an 's' to string)
    """
    if string_plural == None:
        string_plural = "%ss" % string
    word = string_plural
    if count == 1:
        word = string
    return "%d %s" % (count, word)

def pretty_date(dt_secs):
    """
    Get a datetime object or a int() Epoch timestamp and return a
    pretty string like 'an hour ago', 'Yesterday', '3 months ago',
    'just now', etc

    Adapted from http://stackoverflow.com/a/1551394/1523582
    """
    secs_per_day = 24 * 3600
    day_diff = dt_secs // secs_per_day
    second_diff = dt_secs - day_diff * secs_per_day

    if day_diff < 0:
        return ''
    if day_diff == 0:
        if second_diff < 10:
            return "just now"
        if second_diff < 60:
            return pluralize(second_diff, "second")
        if second_diff < 3600:
            return pluralize(second_diff / 60, "minute")
        if second_diff < 86400:
            return pluralize( second_diff / 3600, "hour")
    if day_diff < 7:
        return pluralize(day_diff, "day")
    if day_diff < 31:
        return pluralize(day_diff / 7, "week")
    if day_diff < 365:
        return pluralize(day_diff / 30, "month")
    return pluralize(day_diff / 365, "year")

def read_and_count_lines(linenum, f):
    """Read the next line from f, and increment line-number count"""
    line = re.sub(r"\n$", '', f.readline())
    return (linenum + 1, line)

def next_key(x):
    if len(x) <= 0:
        return 0
    return len(x)

def parse_and_strip_contexts(text):
    """Return (text, contexts) tuple with single-@ contexts stripped out"""
    contexts = []
    for match in re.finditer(r"\s+@{1,2}(?P<context>\w+)", text):
        contexts.append(match.group('context'))
    # First strip/unlabel contexts, then strip opening list characters
    stripped_text = re.sub(r"\s+@\w+", "", text)
    stripped_text = re.sub('@@', '', stripped_text)
    stripped_text = re.sub('^\s*[-*#@]\s*', '', stripped_text)
    return (stripped_text, contexts)

class Plate:
    """Keeps track of everything which is 'on your plate'"""
    
    def __init__(self):
        self._created = datetime.now()
        self.now = self._created
        self.inboxes = {}
        self.next_actions = {}
        self.recurs = {}
        # Timestamp regexes for different types of objects
        self._TS_inbox = (
                r"\s+(?P<date>\d{4}-\d{2}-\d{2})" +
                r"\s+(?P<time>\d{2}:\d{2})" +
                # Mnemonic: "break" is how many days you get a break from seeing
                # this, "window" is how long you see it before it's overdue.
                r"\s+\+(?P<break>\d+),(?P<window>\d+)")

    def stale(self):
        """Check if wiki-files have been updated since we last read them"""
        # Cycle through the files according to their keyboard shortcuts:
        # (i)nboxes, (p)rojects, (s)omeday/maybe, (c)hecklists
        for c in "ipsc":
            last_mtime = os.path.getmtime(vtd_fullpath(c))
            if datetime.fromtimestamp(last_mtime) > self._created:
                return True
        return False


    def read_inboxes(self):
        """List all inboxes, and when they need to be done"""
        # Parse Inboxes file to get our list of inboxes
        linenum = 0
        with open(vtd_fullpath('i')) as f:
            # Skip opening lines
            (linenum, line) = read_and_count_lines(linenum, f)
            while not re.match(vim.eval("g:vtd_section_inbox"), line):
                (linenum, line) = read_and_count_lines(linenum, f)
            # Also skip "Inboxes" section header:
            (linenum, line) = read_and_count_lines(linenum, f)

            # Read inboxes until we hit the "Thoughts" section
            while not re.match(vim.eval("g:vtd_section_thoughts"), line):
                m = re.search(self._TS_inbox, line)
                if m:
                    (text, contexts) = parse_and_strip_contexts(line)
                    last_emptied = datetime.strptime(
                            "%s %s" % m.group('date', 'time'),
                            "%Y-%m-%d %H:%M")
                    vis = last_emptied + timedelta(days=int(m.group('break')))
                    due = vis + timedelta(days=int(m.group('window')))
                    self.inboxes[next_key(self.inboxes)] = dict(
                            name = re.sub(self._TS_inbox, '', text),
                            TS_last = last_emptied,
                            TS_vis  = vis,
                            TS_due  = due,
                            jump_to = "i%d" % linenum,
                            contexts = contexts)
                (linenum, line) = read_and_count_lines(linenum, f)

    def read_projects(self):
        """Scan Projects lists for Next Actions, RECURs, etc."""
        linenum = 0
        with open(vtd_fullpath('p')) as f:
            (linenum, line) = read_and_count_lines(linenum, f)
            current_project = None
            while line:
                if re.match(r"\s*[-*#]\s", line):
                    (linenum, line) = self.process_outline(
                            linenum, line, f, current_project)
                else:
                    if re.match(r"\s*$", line):
                        current_project = None
                    else:
                        current_project = line
                    (linenum, line) = read_and_count_lines(linenum, f)

    def process_outline(self, linenum, line, f, current_project):
        master_indent = opening_whitespace(line)
        list_type = list_start(line)
        while line:
            indent = opening_whitespace(line)
            if indent < master_indent:
                return (linenum, line)
            vim.command("echom 'Here I should skip depending on the list type'")
            if indent > master_indent:
                linetype = list_start(line)
                if linetype:
                    (linenum, line) = self.process_outline(
                            linenum, line, f, current_project)
                else:
                    print "Should append: '%s'" % line
            else:
                if is_next_action(line):
                    print "Add new NextAction: '%s'" % line
                elif is_recur(line):
                    print "Add new RECUR:      '%s'" % line

    def read_all(self):
        """Turn raw text from our wiki files into todo-list items"""
        self.read_inboxes()
        self.read_projects()

    def display_inbox_subset(self, indices, status, summarize):
        if len(indices) < 1:
            return ''
        if summarize:
            return "%s (%d items)  " % (status, len(indices))
        else:
            display = ''
            for i in indices:
                due_diff = seconds_diff(self.inboxes[i]["TS_due"], self.now)
                display += "%s (%s %s) <<%s>>\n" % (self.inboxes[i]["name"],
                        status, pretty_date(abs(due_diff)),
                        self.inboxes[i]["jump_to"])
            return display

    def display_inboxes(self, summarize=False):
        """
        A string representing the currently relevant inboxes.
        
        Arguments:
        summarize - If true, only print how many are overdue and vis,
                    instead of printing everything out
        """
        self.now = datetime.now()
        vis = set(i for i in self.inboxes if (
            self.inboxes[i]["TS_vis"] < self.now and
            self.inboxes[i]["TS_due"] > self.now))
        due = set(i for i in self.inboxes if (
            self.inboxes[i]["TS_due"] < self.now))
        inboxes = ''
        inboxes += self.display_inbox_subset(due, 'Overdue', summarize)
        inboxes += self.display_inbox_subset(vis, 'Due', summarize)
        return inboxes

def trunc_string(string, max_length):
    if not string[(max_length + 1):]:
        return string
    return string[:(max_length - 2)] + '..'

def vtd_dir():
    """The working directory holding all the wiki files"""
    return re.sub(r"~", os.environ['HOME'], vim.eval("g:vtd_wiki_path"))

def vtd_file(abbrev):
    """Return the filename of the requested VTD sourcefile"""
    lower = abbrev.lower()
    if lower == 'i':
        return vim.eval("g:vtd_file_inboxes")
    elif lower == 'p':
        return vim.eval("g:vtd_file_projects")
    elif lower == 's':
        return vim.eval("g:vtd_file_somedaymaybe")
    elif lower == 'c':
        return vim.eval("g:vtd_file_checklists")
    return ''

def vtd_fullpath(abbrev):
    """Return the full pathname of the requested VTD sourcefile"""
    fname = vtd_file(abbrev)
    if len(fname) > 0:
        return os.path.join(vtd_dir(), fname)
    return None

def parse_inboxes():
    inbox_fname = vtd_fullpath('i')
    with open(inbox_fname) as inbox_file:
        inboxes = []
        i_line = inbox_file.readline()
        while (i_line):
            inbox_match = re.search(r"INBOX", i_line)
            if inbox_match:
                inboxes += i_line
            i_line = inbox_file.readline()
    inbox_content = ''.join(inboxes)
    vim.command("let l:inbox_content='%s'" %inbox_content.replace("'", "''"))
    return

def opening_whitespace(string):
    match = re.match(r"(\s*)\S", string)
    if not match:
        return 0
    return match.end(1)

def is_next_action(line):
    """Check if a line of text is structured like a Next Action"""
    return re.match(r"\s*[-#*@]\s+\[\s*\]", line)

def list_start(line):
    """The list-denoting character (if this line starts a list element)"""
    list_match = re.match(r"\s*([-#@*])\s", line)
    if list_match:
        return list_match.group(1)
    return list_match

def blank(line):
    """Checks whether this line contains only whitespace"""
    return re.match(r"\s*$", line)

def proj_done(line):
    """Checks whether this line represents a checked-off project"""
    return re.search(r"DONE(\(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\))?", line)

def sec_header(line):
    """Checks whether this line is a wiki section header"""
    return re.match(r"=+\s+\w", line)

def parse_next_actions():
    p_fname = os.path.join(vtd_dir(), vim.eval("g:vtd_file_projects"))
    with open(p_fname) as p_file:
        p_line = p_file.readline()
        next_actions = []
        while p_line:
            listtype = list_start(p_line)
            if listtype:
                (p_line, new_actions) = parse_next_actions_list(
                        p_line, p_file, cur_proj)
                next_actions.extend(new_actions)
            else:
                if blank(p_line) or proj_done(p_line) or sec_header(p_line):
                    cur_proj = ''
                else:
                    cur_proj = p_line
                p_line = p_file.readline()
    action_lines = []
    for (action, project) in next_actions:
        action_lines += "[] %s (%s)" % (
                trunc_string(action, max_length=60),
                trunc_string(project, max_length=60))
    actions = ''.join(action_lines)
    vim.command("let l:actions='%s'" % actions.replace("'", "''"))
    return

def FillMyPlate():
    """Ensure 'my_plate' variable is up-to-date with everything on my plate"""
    global my_plate
    if 'my_plate' not in globals() or my_plate.stale():
        my_plate = Plate()
        my_plate.read_all()

