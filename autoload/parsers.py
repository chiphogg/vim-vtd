# ============================================================================
# File:        autoload/parsers.py
# Description: Parsers for VTD lists
# Maintainer:  Charles R. Hogg III <charles.r.hogg@gmail.com>
# License:     Distributed under the same terms as vim itself
# ============================================================================

import vim

def parse_inboxes():
    inbox_content = "I haven't a clue how to use Python."
    vim.command("let l:inbox_content='%s'" %inbox_content.replace("'", "''"))
    return
