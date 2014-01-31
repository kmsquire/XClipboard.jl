# XClipboard.jl: Copy and paste in Julia on XWindows systems

This is a partial translation of Ed Rosten's [x_clipboard]
(https://github.com/edrosten/x_clipboard), a nearly complete
demonstration of how to use the clipboard and drag and drop in X11.

(See also [here](http://www.edwardrosten.com/code/x11.html) for a nice
overview.)

At this point, only pasting into Julia is implemented.

Copy-and-paste in general (and on X11 in particular) is actually a
rather tedious experience.  It would be great if there were a higher
level, preferably cross-platform library which took care of this, but
as of mid-2013, I couldn't find one.

Note that Julia Base has a ``clipboard()`` command that already works for
text-based copying.  ``xclipboard()`` is meant to allow any kind of 
data to be pasted, but currently, the parsing of non-text data is up
to the individual.

# Functions

```julia
xclipboard([t1, [t2, ...]])   Get the current contents of the X11
                              clipboard, optionally specifying target
							  types.

xclipboard_targets()          Get a list of possible target types
                              for the current selection

decodemime(::MIME{mime}, x)   Used to decode a particular target
                              type.  Currently handles text, and
                              returns other target types as raw
                              byte arrays.
```

# Example

```julia
julia> using XClipboard

julia> xclipboard_targets()
10-element Array{MIME{mime},1}:
 MIME type TIMESTAMP               
 MIME type TARGETS                 
 MIME type MULTIPLE                
 MIME type SAVE_TARGETS            
 MIME type UTF8_STRING             
 MIME type COMPOUND_TEXT           
 MIME type TEXT                    
 MIME type STRING                  
 MIME type text/plain;charset=utf-8
 MIME type text/plain              

julia> xclipboard()
"Julia: A fresh approach to technical computing"

julia> xclipboard("UTF8_STRING")
"Julia: A fresh approach to technical computing"

julia> xclipboard("text/plain")
"Julia: A fresh approach to technical computing"

julia> xclipboard("text")
ERROR: Requested clipboard target(s) not found.
 in xclipboard at /home/kmsquire/.julia/v0.3/XClipboard/src/XClipboard.jl:37
 in xclipboard at /home/kmsquire/.julia/v0.3/XClipboard/src/XClipboard.jl:45
```

# Misc

* Binary data (such as images) can be received from the clipboard.
  However, decoding is currently left up to the individual.

* Images, in particular, seem to (almost?) always be available as
  ``image/bmp``; however, there is currently no ``bmp`` decoder in
  Julia.

