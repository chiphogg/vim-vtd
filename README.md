# VTD

Vimming Things Done:
a [GTD](http://gettingthingsdone.com/)-ish system which lives in vim.

## What's the big idea?

Text files are great for writing down your projects and tasks.  They're crappy
for figuring out your TODO list at any given moment.  What you need is _software
to parse your text file_ and show you **the things you could be working on
right now**, starting with the most relevant.

VTD is this software.

It creates a special buffer for your TODO list -- the "VTD View" -- whose
contents are based on an underlying text file.  This buffer skips irrelevant
items  -- such as tasks blocked by other tasks, "home" tasks while you're at
work (or vice versa), or tasks you've hidden until a future date.  And the items
it _does_ show are sorted by importance: "Late" before "Due" before "Ready",
with higher-priority items first in each category.

### VTD's syntax

Here are a few VTD syntax basics. For more, see `example.vtd` in this
repository, or the unit tests in
[`chiphogg/libvtd`](https://github.com/chiphogg/libvtd).

```
= A section =

@ An action

# An ordered project: priority one! @p:1
  @ A sub-action (also priority one due to inheritance)
  @ The next sub-action (which is blocked until the first action is done)

- An unordered project
  @ A priority 2 action @p:2
  @ An action with no priority

@ This needs to get done soon! Kind of. <2015-05-15
@ This will be marked as "due" 30 days before the due date <2015-01-01(30)
@ And this can only be done in a long while. >2100-02-14

= More advanced features =

@ Finish reading docs. #readthedocs
@ :vi intro.vtd @after:readthedocs

@ Make some espresso EVERY day [07:00 - 07:45]
  * Comments begin with a '*'.
```

### Features

The following things are _awesome_.

- Priorities, due dates, "hide-until" dates, and contexts are _all inheritable_.
  - e.g., if a project is priority 1, all its tasks will be too by default.
- Checking off a task with `<Space>` is very smooth -- one never has to edit
  the underlying file!
- Undo and redo work flawlessly
- Support for recurring actions (daily, weekly, and monthly), inboxes, and the
  "waiting/delegated" list
- Projects without actions show up in the action list, as `{MISSING Next
  Action}`

### VTD View: "feels like a file"

The VTD View buffer is designed to mimic regular files (wherever it makes
sense). Interacting with the buffer should feel natural to any vim user.

You check off a task by pressing "spacebar" in the VTD View.  Behind the scenes,
this constructs a `patch` command which alters the underlying file, marking the
corresponding line as `DONE`.  VTD then re-reads the file and re-displays your
system, making it feel as if you altered the View buffer directly.

If you made a mistake or changed your mind, you can hit `u` to undo and
`<Ctrl-R>` to redo.  (VTD keeps infinite undo and redo.)

### Known issues

The following are the _biggest pain points_.
- Doesn't support a "project-focused" workflow very well (#3)
  - This is often downright confusing.
- Task display: sometimes gives too much information, sometimes too little (#4)
- Haven't figured out how to add/edit from the View (only checkoffs so far) (#5)

A key goal before hitting 1.0 is that **users should never need to edit the
underlying text file**. (Admittedly, I am pretty far from that goal at the
moment...)

# How to use

## Installation

If you don't have a favourite vim plugin manager, I suggest
[Vundle](https://github.com/gmarik/vundle) or
[NeoBundle](https://github.com/Shougo/neobundle.vim).
Simply add the appropriate line(s) to your `.vimrc`.

**Note that VTD is a [maktaba](https://github.com/google/maktaba)-based
plugin.**  If your plugin manager isn't maktaba-enabled -- and right now, _none_
of them are -- you will also need to install maktaba if you haven't already.

_Highly recommended_: Install [glaive](https://github.com/google/glaive)
for easy configuration. 

### Specific instructions for Vundle and NeoBundle

#### Vundle

```vim
" These lines go after vundle#begin(), and before vundle#end().
Bundle 'google/maktaba'
Bundle 'google/glaive'
Bundle 'chiphogg/vim-vtd'

" This line needs to go after vundle#end().
call glaive#Install()
```

#### NeoBundle

```vim
" These lines go after neobundle#begin(), and before neobundle#end().
NeoBundle 'google/maktaba'
NeoBundle 'google/glaive'
NeoBundle 'chiphogg/vim-vtd'

" This line needs to go after neobundle#end().
call glaive#Install()
```

## Settings

VTD uses maktaba settings. You should set them the easy way, by using Glaive.
For example, let's see how to enable keymappings and set the `files` setting 
to `['~/todo.vtd']`. _With_ Glaive, you can do all that in a single line:

```vim
Glaive vtd plugin[mappings] files=`['~/todo.vtd']`
```

_Without_ Glaive, just use the maktaba settings directly. (And if you don't
know how to do that, install Glaive.)

The following sections list the available VTD settings.

### Required

#### `files`

(**Type**: `List` of `string`s)

The names of the VTD files to read.

Example:
```vim
Glaive vtd files=`['~/todo.vtd', '~/extra.vtd']`
```

### Optional

#### `plugin[mappings]`

**Highly recommended.**

Defines a keymapping to enter the VTD View buffer.

With no arguments, this defaults to `<Leader>t` (see `:help <Leader>`).

If a string argument is supplied, that string will be the keymapping.

Example:
```vim
Glaive vtd plugin[mappings]='qwer'
```
(This sets a mapping for `qwer` to enter the VTD View buffer.)

#### `contexts`

(**Type**: `List` of `string`s)

Contexts to include or exclude by default.
(To exclude a context, preface it with a minus sign.)

Example:
```vim
Glaive vtd contexts=`['work', '-home']`
```

