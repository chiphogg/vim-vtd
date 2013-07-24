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

Rule #1 to keep in mind: __this is written to be *my personal* productivity
system__.  I'm mainly writing it for me.

_Mainly._

But lots of hackers use GTD, and lots use Vim, so I'm making this available in
case others find it useful.  It's also a good way to practice writing vim plugins.

As long as you keep rule #1 in mind, I'd love to hear any feedback.

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
    
