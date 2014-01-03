# VTD

Vimming Things Done: a GTD-ish system which lives in vim, based on the
`vimwiki` plugin.

## Current status

Early stages of development.

`v0.0.1` is fully functional (I used it daily for almost a year). However, it
was a bit of a dead end as far as future maintenance and extensibility.

All subsequent versions are based on a separately-maintained python library,
[libvtd](http://github.com/chiphogg/libvtd).  The advantage is that other
software can use the same library and underlying `.vtd` text file; one could
imagine, for instance, an Android app giving full access to your productivity
system.

## Should _you_ use it?

It's still in a very experimental state, and will be for the foreseeable future.

If you can tolerate upheaval (punctuated by long periods of stasis), then be my
guest!  And please send me any feedback you have.

# Installation

If you don't have a favourite vim plugin manager, I suggest
[Vundle](https://github.com/gmarik/vundle) or
[NeoBundle](https://github.com/Shougo/neobundle.vim).
Simply add the appropriate line(s) to your `.vimrc`.

**Note that VTD is a [maktaba](https://github.com/google/maktaba)-based
plugin.**  If your plugin manager isn't maktaba-enabled -- and right now, _none_
of them are -- you will also need to install maktaba if you haven't already.

_Optional, but highly recommended_: install [glaive](https://github.com/google/glaive)
for easy configuration.

## Specific instructions for Vundle and NeoBundle

### Vundle

```vim
Bundle 'google/maktaba'
Bundle 'google/glaive'
call glaive#Install()

" Install VTD.
Bundle 'chiphogg/vim-vtd'
```

### NeoBundle
```vim
NeoBundle 'google/maktaba'
NeoBundle 'google/glaive'
call glaive#Install()

" Install VTD.
NeoBundle 'chiphogg/vim-vtd'
```

# Settings

VTD uses maktaba settings.  There are two ways to tweak these settings: the easy
way (with Glaive), and the hard way.  For example, let's see how to enable
keymappings and set the `files` setting to `['~/todo.vtd']`.

_Without_ Glaive, you must access maktaba directly, adding the following clunky
lines to your `~/.vimrc`:
```vim
call maktaba#plugin#Install('/full/path/to/vim-vtd')
call maktaba#plugin#Get('vtd').Flag('plugin[mappings]', 1)
call maktaba#plugin#Get('vtd').Flag('files', ['~/todo.vtd'])
```
You need one line to install the plugin, and an additional line for every
setting you want to change.

_With_ Glaive, you can do all that in a single line.
```vim
Glaive vtd plugin[mappings] files=`['~/todo.vtd']`
```
Note that we don't have to install the plugin (and worry about the path); glaive
does this for us.

The following sections list the available VTD settings.

## Required

### `files`

(**Type**: `List` of `string`s)

The names of the VTD files to read.

Example:
```vim
Glaive vtd files=`['~/todo.vtd', '~/extra.vtd']`
```

## Optional

### `plugin[mappings]`

**Highly recommended.**

Defines a keymapping to enter the VTD View buffer.

With no arguments, this defaults to `<Leader>t` (see `:help <Leader>`).

If a string argument is supplied, that string will be the keymapping.

Example:
```vim
Glaive vtd plugin[mappings]='qwer'
```
(This sets a mapping for `qwer` to enter the VTD View buffer.)

### `contexts`

(**Type**: `List` of `string`s)

Contexts to include or exclude by default.
(To exclude a context, preface it with a minus sign.)

Example:
```vim
Glaive vtd contexts=`['work', '-home']`
```

# Acknowledgements

## GTD

  - Obviously, 
     [David Allen's original book]
     (https://secure.davidco.com/store/catalog/GETTING-THINGS-DONE-PAPERBACK-p-16175.php)
  - [Leo Babauta](http://leobabauta.com/), for
     [making GTD more accessible]
     (http://zenhabits.net/zen-to-done-ztd-the-ultimate-simple-productivity-system/)

## Coding

  - [Steve Losh](http://stevelosh.com/).
    Vimscript was always impenetrable to me.  Then I found Steve's 
    [advice for Writing Vim Plugins]
    (http://stevelosh.com/blog/2011/09/writing-vim-plugins/),
    and his thorough tutorial,
    ["Learn Vimscript the Hard Way"]
    (http://learnvimscriptthehardway.stevelosh.com/).
    Finally, a foothold!
  - [Tim Pope](http://tpo.pe/).
    I must use about a million of his plugins;
    they make life easier in so many little ways.
    Not to mention, he *saved Vim plugins* when he wrote
    [pathogen](https://github.com/tpope/vim-pathogen/).
    I use [vundle](https://github.com/gmarik/vundle/) instead
    (it handles synchronization better),
    but even vundle was inspired by pathogen.
  - [scrooloose](https://github.com/scrooloose).
    Reading through his code was a revelatory experience:
    nicely sectioned and thoroughly commented,
    this is vimscript that _looks good_.
    It's certainly helped the code for VTD;
    my code for the view window draws *heavily*
    from his code for the tree window.
    I wish I'd found the
    [NERDtree](https://github.com/scrooloose/nerdtree)
    source sooner!
    
