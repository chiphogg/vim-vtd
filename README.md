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
Simply add the appropriate line to your `.vimrc`.

**Note that VTD requires [maktaba](https://github.com/google/maktaba).**  You
will also need to install maktaba if you haven't already.

_Optional, but recommended_: install [glaive](https://github.com/google/glaive)
for easy configuration.

## Specific instructions for Vundle and NeoBundle

### Vundle

```vim
" Install maktaba (required).
Bundle 'google/maktaba'
" Glaive is optional, but recommended.
Bundle 'google/glaive'
call glaive#Install()

" Install VTD.
Bundle 'chiphogg/vim-vtd'
```

### NeoBundle
```vim
" Install maktaba (required).
NeoBundle 'google/maktaba'
" Glaive is optional, but recommended.
NeoBundle 'google/glaive'
call glaive#Install()

" Install VTD.
NeoBundle 'chiphogg/vim-vtd'
```

## Optional configuration using Glaive

This part works with any plugin manager, but it has to come _after_ the lines
which add your bundles to the RTP.  (i.e., after the lines from the previous
section.)

This example shows how to enable VTD's keymapping (and set it to ",t"), and how
to include the 'home' context and exclude the 'work' context by default.

```vim
Glaive vim_vtd plugin[mappings]=',t' contexts=`['home', '-work']`
```

# Acknowledgements

## GTD

  - Obviously, 
     [David Allen's original book]
     (https://secure.davidco.com/store/catalog/GETTING-THINGS-DONE-PAPERBACK-p-16175.php)
  - [Leo Babauta](http://leobabauta.com/), for
     [making GTD more accessible]
     (http://zenhabits.net/zen-to-done-ztd-the-ultimate-simple-productivity-system/)
  - I got the "Thoughts" inbox from
     [Thinking Rock GTD software](http://www.trgtd.com.au/),
     which I explored a few years ago.

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
    
