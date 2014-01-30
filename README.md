# XClipboard.jl: Copy and paste in Julia on XWindows systems

This is a partial translation of @edrosten's [x_clipboard]
(https://github.com/edrosten/x_clipboard) nearly complete
demonstration of how to use the clipboard and drag and drop in X11.

(See also [here](http://www.edwardrosten.com/code/x11.html) for a nice
overview.)

At this point, only pasting is (mostly) implemented.

Copy-and-paste in general (and on X11 in particular) is actually a
rather tedious experience.  It would be great if there were a higher
level, preferably cross-platform library which took care of this, but
as of mid-2013, I couldn't find one.

So, I started this package.  Hopefully it will be useful at some point.
