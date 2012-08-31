# This Python file uses the following encoding: utf-8

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
from calendar import monthrange
import time
import string

# Load guard:
try:
    AUTOLOAD_PARSERS_PY
except NameError:
    AUTOLOAD_PARSERS_PY = True;

def offset_in_month(year, month, offset):
    """
    Day of month having this offset ('3' is 3rd day of month, '-1' is last)
    """
    month_length = monthrange(year, month)[1]
    if offset < 0: offset += 1
    return (month_length + offset - 1) % month_length + 1

def decode_dow(dow):
    """Turn 3-capital-letter abbreviation into day-of-week number.

    Arguments:
    dow - A 3-capital-letter abbreviation of the day of week (e.g., "SUN")

    Return:
    A number whose meaning is the same as datetime.date.weekday() (i.e., 0 for
    Monday and 6 for Sunday)
    """
    dow_list = {
            'MON': 0,
            'TUE': 1,
            'WED': 2,
            'THU': 3,
            'FRI': 4,
            'SAT': 5,
            'SUN': 6,
            }
    try:
        day_num = dow_list[dow]
    except KeyError:
        day_num = None
    return day_num

def closest_dow(target, date):
    """Find the closest target (e.g., closest Monday) to date

    Arguments:
    target - An integer from 0 to 6 representing the weekday (as in
        datetime.datetime.weekday())
    date - The date to adjust

    Return:
    A datetime object representing the closest given-DOW to the given date.
    """
    date_dow = date.weekday()
    delta = (target + 7 - date_dow) % 7
    if delta > 3:
        delta -= 7
    return date + timedelta(days=delta)

def set_time_to_string(date, time_str):
    """A datetime object whose date is 'date' and time is from 'time_str'

    Arguments:
    date - A datetime object
    time_str - A string in "%H:%M" (i.e., "hh:mm") format

    Returns:
    A datetime object on the same day as 'date' but whose time is 'time_str'
    """
    date_fmt = "%Y-%m-%d"
    new_date = datetime.strptime("%s %s" % (date.strftime(date_fmt), time_str),
            "%s %%H:%%M" % date_fmt)
    return new_date

def next_day_week(last_done, match):
    """Visible- and Due-dates for day-of-week type RECURs"""
    (vis, due) = (last_done, last_done)
    last_dow = last_done.weekday()
    time_chunk = 7  # days in a week
    if match.group("num"): time_chunk *= int(match.group("num"))
    recur_dow = decode_dow(match.group("dow"))

    # Calculate the due-DATE
    if match.group("anchor"):
        # anchor means "Every N weeks past *this date*": it 'anchors' the
        # repeating.  Use it for, e.g., handing in timesheets every 2 weeks.
        anchor = datetime.strptime(match.group("anchor"), "%Y-%m-%d")
    else:
        # If there's no anchor, we're "free-floating":
        # anchor to the last time we completed the task.
        anchor = last_done.replace(hour=0, minute=0, second=0)
    anchor_date = closest_dow(recur_dow, anchor)
    elapsed_days = (last_done - anchor_date).days
    days_left = time_chunk - (elapsed_days % time_chunk)
    vis = anchor_date + timedelta(days=elapsed_days + days_left)

    # Calculate the due-TIME
    due = vis.replace(hour=23, minute=59)  # Defaults to due at end of day
    if match.group("dow_due"):
        due = set_time_to_string(due, match.group("dow_due"))
    if match.group("dow_vis"):
        vis = set_time_to_string(vis, match.group("dow_vis"))
    print last_done
    print vis
    return (vis, due)

def next_day_month(date, offset):
    """The next day after 'date' which has the right offset within the month"""
    # It will either be the same month, or the following month
    day_in_month = offset_in_month(date.year, date.month, offset)
    new_date = date.replace(day=day_in_month, hour=0, minute=0)
    if new_date > date:
        return new_date
    # If that didn't work, let's go to the next month
    new_date = new_date.replace(day=1) + timedelta(days=32)
    day_in_month = offset_in_month(new_date.year, new_date.month, offset)
    new_date = new_date.replace(day=day_in_month)
    return new_date

def sort_by_timestamp(i, items, field):
    """Sort collection of items by a timestamp field"""
    key = lambda i: (time.mktime(items[i][field].timetuple())
            if items[i][field] else float('inf'))
    return sorted(i, key=key)

def time_window(window):
    """ The window of time (in days) specified by this string

    Arguments:
    window - The result of a regex match; should be either a bunch of digits, or
    empty (in which case, a 1-day window is assumed).
    """
    try:
        if len(window):
            return int(window)
        return 1
    except:
        return 1

def vtdview_section_marker(summarize):
    """ Marker for the beginning of a vtdview section

    Depends on whether the section is summarized or not
    """
    if summarize:
        return "▸"
    else:
        return "▾"

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
    line = f.readline()
    if not line:
        return (0, line)  # Either one will evaluate to false
    # Remove trailing newline:
    line = re.sub(r"\n$", '', line)
    return (linenum + 1, line)

def next_key(x):
    if len(x) <= 0:
        return 0
    return len(x)

def parse_datetime(string, date_type = ''):
    """Turn datestamp (followed by optional timestamp) into a datetime object

    Arguments:
    string - A string containing the date/time stamp
    date_type - An optional string: '<' for due, '>' for visible.
    """
    if len(string) == 10:
        time = '00:01'
        if date_type == '<':
            time = '23:59'
        string = "%s %s" % (string, time)
    if len(string) == 16:
        return datetime.strptime(string, "%Y-%m-%d %H:%M")
    return None

def parse_and_strip_dates(text):
    """Find any vis/due-dates, parse them, and strip them out"""
    (vis, due) = (None, None)
    date_pattern = r"\s+(?P<type>[<>])" + vim.eval("g:vtd_datetime_regex")
    for match in re.finditer(date_pattern, text):
        if match.group('type') == '>':
            vis = parse_datetime(match.group('datetime'), match.group('type'))
        elif match.group('type') == '<':
            due = parse_datetime(match.group('datetime'), match.group('type'))

    # It seems inefficient to do *another* regex search, since we know all the
    # matches already.  But if I just removed each match inside the loop, that
    # would change the start/end indices of *other* matches.  This seems
    # conceptually clearer, and besides I don't performance being an issue.
    stripped_text = re.sub(date_pattern, '', text)
    return (stripped_text, vis, due)

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

def list_counter(list_type):
    """A counter telling how many elements to process from a list

    Arguments:
    list_type - The character used to mark list items

    Here are the semantics for each type:
        '*' - Project Support material.  Treat this as "comments";
            skip 'em all (return 0)
        '#' - Ordered list.  Skip everything after the first (return 1)
        '-' - Unordered list.  Don't skip anything (return True)
    """
    if list_type == '*':
        return 0
    elif list_type == '#':
        return 1
    return True

def update_list_counter(counter):
    """Set counter to reflect that we have processed one more list element

    Arguments:
    counter - Like the return value of list_counter: either the number of list
        items left to process, or 'True' if there is no limit.
    """
    if not counter or isinstance(counter, bool):
        return counter
    return counter - 1

def context_list_string(c_list):
    """A context list in plaintext with proper grammar"""
    previous = None
    contexts = ''
    comma = ''
    for c in c_list:
        if previous:
            contexts += comma + previous
            comma = ', '
        previous = c
    if len(contexts):
        contexts += ' or '
    return contexts + previous

class Plate:
    """Keeps track of everything which is 'on your plate'"""
    
    def __init__(self):
        self._created = datetime.now()
        self.now = self._created
        self.inboxes = {}
        self.next_actions = {}
        self.recurs = {}
        self.reminders = {}

        # A few helpful regexes...
        # Mnemonic: "break" is how many days you get a break from seeing this,
        # "window" is how long you see it before it's overdue.
        break_window = r"\+(?P<break>\d+)(,(?P<window>\d+))?"
        # Day of week has format N*DOW: e.g., 3*TUE means "every 3rd Tuesday"
        # e.g., 2*TUE(2012-09-04 17:00-22:00) means "every second Tuesday,
        #   starting 2012-09-04, visible 17:00 and due by 22:00"
        no_paren = r"(?!\))"  # helps make sure parenthesis non-empty
        dow_anchor = r"(?P<anchor>\d{4}-\d{2}-\d{2})?"
        self.dow_times = r"(((?P<dow_vis>\d{2}:\d{2})-)?(?P<dow_due>\d{2}:\d{2}))?"
        day_of_week = (r"((?P<num>\d+)\*)?" +
                r"(?P<dow>(MON)|(TUE)|(WED)|(THU)|(FRI)|(SAT)|(SUN))" +
                r"(\(" + no_paren + dow_anchor + r"\s*" + self.dow_times + r"\))?")
                #r"(\(" + no_paren + dow_anchor + r"\s*" + dow_times + r"\))?")
        # Day of month; negative numbers count from the end.
        # e.g., M+3 means "3rd day of the month"
        # e.g., M-7,3 means "visible on 7th-last day of month; 3-day window"
        day_of_month = r"M(?P<offset>[+-]\d+)(,(?P<window_dom>\d+))?"

        # Timestamp regexes for different types of objects
        self._TS_inbox = (vim.eval("g:vtd_datetime_regex") + r"\s+" +
                break_window)
        self._TS_remind = (r"\s*REMIND\s*" +
                vim.eval("g:vtd_datetime_regex"))
        self._TS_recur = (r"\s*RECUR\s*" +
                vim.eval("g:vtd_datetime_regex") + r"\s+" +
                r"((" + break_window + r")" +
                r"|(" + day_of_week  + r")" +
                r"|(" + day_of_month + r"))")


    def stale(self):
        """Check if wiki-files have been updated since we last read them"""
        # Cycle through the files according to their keyboard shortcuts:
        # (i)nboxes, (p)rojects, (s)omeday/maybe, (c)hecklists
        for c in "ipsc":
            last_mtime = os.path.getmtime(vtd_fullpath(c))
            if datetime.fromtimestamp(last_mtime) > self._created:
                return True
        return False

    def visible(self, vis):
        """Tells whether we should see an item which is visible after 'vis'

        Arguments:
        vis - A datetime object representing the "visible-time" for some item;
        could also be None, in which case the item is *always* visible
        """
        if vis is None:
            return True
        return vis < self.now

    def overdue(self, due):
        """Tells whether an item due on 'due' is overdue

        Arguments:
        due - A datetime object representing the "due-time" for some item; could
        also be None, in which case the item is *never* overdue
        """
        if due is None:
            return False
        return due < self.now

    def update_time_and_contexts(self):
        # Updating the time is easy
        self.now = datetime.now()

        # Only update our context list if we haven't yet,
        # OR if the context file has since been updated:
        context_file = vim.eval("g:vtd_contexts_file")
        context_file = re.sub(r"~", os.environ['HOME'], context_file)
        context_updated = os.path.getmtime(context_file)
        if (not hasattr(self, '_context_checked')
                or datetime.fromtimestamp(context_updated) > self._context_checked):
            self._context_checked = self.now
            self.contexts_use = []
            self.contexts_avoid = []
            with open(context_file) as f:
                for line in f:
                    line = re.sub(r"#.*$", '', line)
                    if re.match(r"\s*$", line):
                        continue
                    contexts = line.split()
                    for context in contexts:
                        if context[0] == '-':
                            self.contexts_avoid.append(context[1:])
                        else:
                            self.contexts_use.append(context)

    def contexts_ok(self, contexts, include_anon=False):
        """Check if the supplied context list means this item should be shown
        """
        matches_context = False
        for context in contexts:
            if context in self.contexts_avoid:
                return False
            if context in self.contexts_use:
                matches_context = True
        return matches_context or include_anon

    def add_recur(self, linenum, line):
        """Parse 'line' and add a new RECUR to the list"""
        m = re.search(self._TS_recur, line)
        (line, contexts) = parse_and_strip_contexts(line)
        last_done = parse_datetime(m.group('datetime'))
        vis = due = None
        if m.group("break"):
            d_vis = timedelta(days=int(m.group("break")))
            d_due = timedelta(days=time_window(m.group("window")))
        elif m.group("dow"):
            (vis, due) = next_day_week(last_done, m)
        elif m.group("offset"):
            vis = next_day_month(last_done, int(m.group("offset")))
            d_due = timedelta(days=time_window(m.group("window_dom")))
        else:
            print "Syntax error line %d" % linenum
            return False
        if not vis: vis = last_done + d_vis
        if not due: due = vis + d_due
        self.recurs[next_key(self.recurs)] = dict(
                name = re.sub(self._TS_recur, '', line),
                TS_last = last_done,
                TS_vis = vis,
                TS_due = due,
                jump_to = "p%d" % linenum,
                contexts = contexts)
        return True

    def add_NextAction(self, linenum, line):
        """Parse 'line' and add a new NextAction to the list"""
        if item_done(line):
            return False
        (line, contexts) = parse_and_strip_contexts(line)
        (line, vis, due) = parse_and_strip_dates(line)
        text = re.sub('^\s*@\s+', '', line)
        self.next_actions[next_key(self.next_actions)] = dict(
                name = text,
                TS_vis = vis,
                TS_due = due,
                jump_to = "p%d" % linenum,
                contexts = contexts)
        return True

    def read_inboxes(self):
        """List all inboxes, and when they need to be done"""
        # Parse Inboxes file to get our list of inboxes
        linenum = 0
        with open(vtd_fullpath('i')) as f:
            # Skip opening lines
            (linenum, line) = read_and_count_lines(linenum, f)
            while linenum and not re.match(vim.eval("g:vtd_section_inbox"), line):
                (linenum, line) = read_and_count_lines(linenum, f)
            # Also skip "Inboxes" section header:
            (linenum, line) = read_and_count_lines(linenum, f)
            # Read inboxes until we hit the "Thoughts" section
            while linenum and not re.match(vim.eval("g:vtd_section_thoughts"), line):
                m = re.search(self._TS_inbox, line)
                if m:
                    (text, contexts) = parse_and_strip_contexts(line)
                    last_emptied = parse_datetime(m.group('datetime'))
                    vis = last_emptied + timedelta(days=int(m.group('break')))
                    window = time_window(m.group('window'))
                    due = vis + timedelta(days=window)
                    self.inboxes[next_key(self.inboxes)] = dict(
                            name = re.sub(self._TS_inbox, '', text),
                            TS_last = last_emptied,
                            TS_vis  = vis,
                            TS_due  = due,
                            jump_to = "i%d" % linenum,
                            contexts = contexts)
                (linenum, line) = read_and_count_lines(linenum, f)

            # Now look for the Reminders section. Skip until it starts:
            remind_header = vim.eval("g:vtd_section_reminders")
            while linenum and not re.match(remind_header, line):
                (linenum, line) = read_and_count_lines(linenum, f)
            # Also skip "Reminders" section header itself:
            (linenum, line) = read_and_count_lines(linenum, f)
            # Read Reminders until EOF
            while linenum:
                m = re.search(self._TS_remind, line)
                if m and not item_done(line):
                    (text, contexts) = parse_and_strip_contexts(line)
                    remind_when = parse_datetime(m.group('datetime'))
                    self.reminders[next_key(self.reminders)] = dict(
                            name = re.sub(self._TS_remind, '', text),
                            TS   = remind_when,
                            jump_to = "i%d" % linenum,
                            contexts = contexts)
                (linenum, line) = read_and_count_lines(linenum, f)

    def read_projects(self):
        """Scan Projects lists for Next Actions, RECURs, etc."""
        linenum = 0
        with open(vtd_fullpath('p')) as f:
            (linenum, line) = read_and_count_lines(linenum, f)
            current_project = None
            while linenum:
                if list_start(line):
                    (linenum, line) = self.process_outline(
                            linenum, line, f, current_project)
                else:
                    if blank(line):
                        current_project = None
                    else:
                        current_project = line
                    (linenum, line) = read_and_count_lines(linenum, f)

    def process_outline(self, linenum, line, f, current_project):
        master_indent = opening_whitespace(line)
        list_type = list_start(line)
        # A 'blocker' is an ordered-list item which is not done.  As soon as we
        # find one, we ignore all subsequent elements of that ordered list.
        blocker_started = blocker_finished = False
        # If any parent is marked DONE, we also ignore these lines
        parent_done = False
        while linenum:
            indent = opening_whitespace(line)
            if indent < master_indent:
                # If this line is less indented than the list we're processing,
                # we know we're done.
                return (linenum, line)
            if list_type == '#' and blocker_finished:
                # It doesn't matter what's on this line if it's blocked!
                (linenum, line) = read_and_count_lines(linenum, f)
                continue
            if indent > master_indent:
                # Anything *more* indented than this list gets processed
                # recursively (unless it's not a list element, in which case it
                # should be appended to what we already started).
                if parent_done:
                    (linenum, line) = read_and_count_lines(linenum, f)
                    continue
                linetype = list_start(line)
                if linetype:
                    (linenum, line) = self.process_outline(
                            linenum, line, f, current_project)
                else:
                    print "Should append: '%s'" % line
                    (linenum, line) = read_and_count_lines(linenum, f)
            else:
                # What to do with a line indented the *same* as this list:
                if blocker_started:
                    blocker_finished = True
                    continue
                if item_done(line):
                    parent_done = True
                else:
                    parent_done = False
                    if list_type == '#':
                        blocker_started = True
                if is_next_action(line):
                    self.add_NextAction(linenum, line)
                elif is_recur(line):
                    self.add_recur(linenum, line)
                (linenum, line) = read_and_count_lines(linenum, f)
        return (linenum, line)

    def read_all(self):
        """Turn raw text from our wiki files into todo-list items"""
        self.read_inboxes()
        self.read_projects()

    def display_contexts(self):
        """String: the context info for the VTD view window"""
        self.update_time_and_contexts()
        have_contexts = len(self.contexts_use)
        have_avoided_contexts = len(self.contexts_avoid)

        # Default values: all strings are empty.
        use = but = avoid = ""
        # Change strings to appropriate values
        if have_contexts:
            use = context_list_string(self.contexts_use)
        if have_avoided_contexts:
            avoid = 'NOT ' + context_list_string(self.contexts_avoid)
        if have_contexts and have_avoided_contexts:
            but = ' but '
        context_string = use + but + avoid

        contexts = "%s Contexts: %s\n" % (
                vtdview_section_marker(True),  # Always summarize... for now!
                context_string)
        return contexts

    def display_recur_subset(self, indices, status, summarize):
        if len(indices) < 1:
            return ''
        if summarize:
            return "%s (%d items)  " % (status, len(indices))
        else:
            display = ''
            i_sorted = sort_by_timestamp(indices, self.recurs, "TS_due")
            for i in i_sorted:
                due_diff = seconds_diff(self.recurs[i]["TS_due"], self.now)
                display += "\n  - %s (%s %s) <<%s>>" % (self.recurs[i]["name"],
                        status, pretty_date(abs(due_diff)),
                        self.recurs[i]["jump_to"])
            return display

    def display_recurs(self):
        """A string representing the currently relevant recurring actions."""
        summarize = (vim.eval("s:vtdview_summarize_recur") == "1")
        self.update_time_and_contexts()
        vis = set(i for i in self.recurs if (
            self.visible(self.recurs[i]["TS_vis"]) and
            not self.overdue(self.recurs[i]["TS_due"]) and
            self.contexts_ok(self.recurs[i]["contexts"])))
        due = set(i for i in self.recurs if (
            self.overdue(self.recurs[i]["TS_due"]) and
            self.contexts_ok(self.recurs[i]["contexts"])))
        recurs = "%s Recurring Actions: %s%s\n" % (
                vtdview_section_marker(summarize),
                self.display_recur_subset(due, 'Overdue', summarize),
                self.display_recur_subset(vis, 'Due', summarize))
        return recurs


    def display_inbox_subset(self, indices, status, summarize):
        if len(indices) < 1:
            return ''
        if summarize:
            return "%s (%d items)  " % (status, len(indices))
        else:
            display = ''
            i_sorted = sort_by_timestamp(indices, self.inboxes, "TS_due")
            for i in i_sorted:
                due_diff = seconds_diff(self.inboxes[i]["TS_due"], self.now)
                display += "\n  - %s (%s %s) <<%s>>" % (self.inboxes[i]["name"],
                        status, pretty_date(abs(due_diff)),
                        self.inboxes[i]["jump_to"])
            return display

    def display_inboxes(self):
        """
        A string representing the currently relevant inboxes.
        
        Arguments:
        summarize - If true, only print how many are overdue and vis,
                    instead of printing everything out
        """
        summarize = (vim.eval("s:vtdview_summarize_inbox") == "1")
        self.update_time_and_contexts()
        vis = set(i for i in self.inboxes if (
            self.visible(self.inboxes[i]["TS_vis"]) and
            not self.overdue(self.inboxes[i]["TS_due"]) and
            self.contexts_ok(self.inboxes[i]["contexts"])))
        due = set(i for i in self.inboxes if (
            self.overdue(self.inboxes[i]["TS_due"]) and
            self.contexts_ok(self.inboxes[i]["contexts"])))
        inboxes = "%s Inboxes: %s%s\n" % (
                vtdview_section_marker(summarize),
                self.display_inbox_subset(due, 'Overdue', summarize),
                self.display_inbox_subset(vis, 'Due', summarize))
        return inboxes

    def display_reminders(self):
        """String: the reminders info for the VTD view window"""
        summarize = (vim.eval("s:vtdview_summarize_remind") == "1")
        self.update_time_and_contexts()
        vis = set(i for i in self.reminders if (
            self.visible(self.reminders[i]["TS"]) and
            self.contexts_ok(self.reminders[i]["contexts"], True)))
        reminders = "%s Reminders: %s\n" % (
                vtdview_section_marker(summarize),
                self.display_reminder_subset(vis, 'Visible', summarize))
        return reminders

    def display_reminder_subset(self, indices, status, summarize):
        if len(indices) < 1:
            return ''
        if summarize:
            return "(%d items %s)  " % (len(indices), status)
        else:
            display = ''
            i_sorted = sort_by_timestamp(indices, self.reminders, "TS")
            for i in i_sorted:
                due_tag = ''
                if self.reminders[i]["TS"]:
                    due_diff = seconds_diff(self.reminders[i]["TS"], self.now)
                    due_tag = " (%s %s)" % (status, pretty_date(abs(due_diff)))
                display += "\n  - %s %s<<%s>>" % (self.reminders[i]["name"],
                        due_tag, self.reminders[i]["jump_to"])
            return display

    def display_action_subset(self, indices, status, summarize):
        if len(indices) < 1:
            return ''
        if summarize:
            return "%s (%d items)  " % (status, len(indices))
        else:
            display = ''
            i_sorted = sort_by_timestamp(indices, self.next_actions, "TS_due")
            for i in i_sorted:
                due_tag = ''
                if self.next_actions[i]["TS_due"]:
                    due_diff = seconds_diff(self.next_actions[i]["TS_due"], self.now)
                    due_tag = " (%s %s)" % (status, pretty_date(abs(due_diff)))
                display += "\n  - %s %s<<%s>>" % (self.next_actions[i]["name"],
                        due_tag, self.next_actions[i]["jump_to"])
            return display

    def display_NextActions(self):
        """A string representing the current NextActions list"""
        summarize = (vim.eval("s:vtdview_summarize_nextActions") == "1")
        self.update_time_and_contexts()
        vis = set(i for i in self.next_actions if (
            self.visible(self.next_actions[i]["TS_vis"]) and
            not self.overdue(self.next_actions[i]["TS_due"]) and
            self.contexts_ok(self.next_actions[i]["contexts"])))
        due = set(i for i in self.next_actions if (
            self.overdue(self.next_actions[i]["TS_due"]) and
            self.contexts_ok(self.next_actions[i]["contexts"])))
        actions = "%s Next Actions: %s%s\n" % (
                vtdview_section_marker(summarize),
                self.display_action_subset(due, 'Overdue', summarize),
                self.display_action_subset(vis, 'Due', summarize))
        return actions

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
    vim.command("let l:inbox_content='%s'" % inbox_content.replace("'", "''"))
    return

def opening_whitespace(string):
    match = re.match(r"(\s*)\S", string)
    if not match:
        return 0
    return match.end(1)

def is_recur(line):
    """Check if a line of text is structured like a RECURring action"""
    return re.search(r"RECUR", line)

def item_done(line):
    """Check if a line of text is marked as "done"

    Arguments:
    line - A line of text from a file (usually the Projects file)
    """
    return re.search(r"(DONE|WONTDO)", line)

def is_next_action(line):
    """Check if a line of text is structured like a Next Action

    Arguments:
    line - A line of text from a file (usually the Projects file)

    A NextAction fulfils two criteria:
        a) It's a "list"-type line (starts with a list marker),
        b) It begins with an isolated '@' symbol
    """
    list_type = list_start(line)
    if not list_type:
        return False
    return re.match(r"\s*[%s]\s+@\s" % list_type, line)

def list_start(line):
    """The list-denoting character (if this line starts a list element)"""
    list_match = re.match(r"\s*([-#@*])\s", line)
    if list_match:
        return list_match.group(1)
    return list_match

def blank(line):
    """Checks whether this line contains only whitespace"""
    return re.match(r"\s*$", line)

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
                if blank(p_line) or item_done(p_line) or sec_header(p_line):
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

