# ============================================================================
# File:        autoload/parsers.py
# Description: Parsers for VTD lists
# Maintainer:  Charles R. Hogg III <charles.r.hogg@gmail.com>
# License:     Distributed under the same terms as vim itself
# ============================================================================

import vim
import re
import os
import datetime
import string

inbox_pattern = 'INBOX\s+(\d{4}-\d{2}-\d{2})(\s+(\d{2}:\d{2}))?\s+\+(\d)'

class OutlineProcessor:
    """A processor for outline-structured datafiles"""

    def __init__(self, start_re, end_re):
        """
        Arguments:
        start_re -- A regex describing the "start line": discard lines up to and
            including the first match
        end_re -- A regex describing the "end line": if we find a match, stop
            processing and return

        """
        self._start = start_re
        self._end = end_re
        self._inboxes = []

    def parse_file(self, next_line, f):
        """Parse 
        """
        print "Not really anything yet!"

datetime_re = ''.join([r"(\d{4}-\d{2}(-\d{2})?)",   # date
                       r"(\d{2}:\d{2})?",           # time (optional)
                       r"(\s+[+-]\d+w?)?",          # offset (optional)
                       ''])

class KeywordChecker:
    """Keeps a list of lines of text which match a keyword"""

    def __init__(self, keyword, keyword_re):
        """
        Arguments:
        keyword -- The name of the keyword (e.g., 'INBOX')
        keyword_re -- A regex describing what the keyword looks like

        """
        self._title = keyword
        self._regex = keyword_re
        self.items = []

    def keyword_regex(self):
        """The full regex (including date/time-strings) for this keyword)"""
        regex = ''.join([r"(", self._regex, r")\s+(>\s*", datetime_re,
            r")?(<\s*", datetime_re, r")?\s*$"])
        return regex

    def check(self, line):
        match = re.search(self.keyword_regex(), line)
        if !match:
            return False



class Inbox:
    def __init__(self, match):
        self._contexts = []

def parse_inboxes():
    wiki_path = vim.eval("g:vtd_wiki_path")
    inbox_fname = vim.eval("g:vtd_file_inboxes")
    inbox_file = open(os.path.join(
        os.environ['HOME'], wiki_path, inbox_fname))
    inboxes = []
    i_line = inbox_file.readline()
    while (i_line):
        inbox_match = re.search(inbox_pattern, i_line)
        if inbox_match:
            inboxes += i_line
        i_line = inbox_file.readline()
    inbox_content = ''.join(inboxes)
    vim.command("let l:inbox_content='%s'" %inbox_content.replace("'", "''"))
    return
