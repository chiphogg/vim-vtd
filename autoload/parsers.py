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
