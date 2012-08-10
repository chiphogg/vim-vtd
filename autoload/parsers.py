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

def trunc_string(string, max_length):
    if not string[(max_length + 1):]:
        return string
    return string[:(max_length - 2)] + '..'

def vtd_dir():
    return re.sub(r"~", os.environ['HOME'], vim.eval("g:vtd_wiki_path"))

def parse_inboxes():
    inbox_fname = os.path.join(vtd_dir(), vim.eval("g:vtd_file_inboxes"))
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

def parse_NextActions_recurse(p_line, p_file):
    master_indent = opening_whitespace(p_line)
    # LOGIC:
    # 1) Does it not even start with a list char?  Tack it on to the previous line and read the next one.
    # 2) So it's a listy thing. Check the indentation level, and either return or recurse.
    # 3) If it's a list, and it's at our indentation level, PROCESS.
    while p_line:
        linetype = re.match(r"\s*([-#@*])", p_line)
        if not linetype:

        indent = opening_whitespace(p_line)
        if indent < master_indent:
            return (pline, p_file)
        elif indent > master_indent:
            (pline, p_file) = parse_NextActions_recurse(pline, p_file)
        p_line = p_file.readline()

def list_start(line):
    list_match = re.match(r"\s*(-#@*])", line)
    if list_match:
        return list_match.end(1)
    return list_match

def parse_next_actions():
    p_fname = os.path.join(vtd_dir(), vim.eval("g:vtd_file_projects"))
    with open(p_fname) as p_file:
        p_line = p_file.readline()
        while p_line:
            listtype = list_start(p_line)
            if listtype:

        next_actions = parse_NextActions_recurse(p_line, p_file)
    # So now the "next_actions" variable has a list of matching lines.
    # Okay; what to do with them?
    # Well, perhaps it's better if it has not just the line, but the context (if
    # any).  i.e., the Project it comes from.
    # So it's a list of tuples (line, project) where project may be None.
    action_lines = []
    for (action, project) in next_actions:
        action_lines += "[] %s (%s)" % (
                trunc_string(action, max_length=60),
                trunc_string(project, max_length=60))
    actions = ''.join(action_lines)
    vim.command("let l:actions='%s'" % actions.replace("'", "''"))
    return
