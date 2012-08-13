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
    if (

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

def is_next_action(line):
    return re.match(r"\s*[-#*@]\s+\[\s*\]", line)

def parse_next_actions_list(line, p_file, cur_proj):
    master_indent = opening_whitespace(line)
    master_linetype = list_start(line)
    prev_line = ''
    next_actions = []
    while line:
        linetype = list_start(line)
        # If this line doesn't start a new list element, tack its content onto
        # whatever came before.
        if not linetype:
            prev_line = prev_line + line
            line = p_file.readline()
        else:
            prev_line = ''
            indent = opening_whitespace(line)
            # If this line is indented less than this list, we must be done
            if indent < master_indent:
                return (line, next_actions)
            # If it's indented *more*, it's a new list; recursively parse it
            elif indent > master_indent:
                (line, new_actions) = parse_next_actions_list(
                        line, p_file, prev_line)
                next_actions.extend(new_actions)
            # It must be a new element of the same list
            else:
                if is_next_action(line):
                    next_actions.append((line, cur_proj))
                line = p_file.readline()
    return line, next_actions

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
