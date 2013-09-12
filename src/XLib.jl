# xlib integration for interacting with the clipboard

#module XLib

import Base: string

#if dlopen_e("libX11") != C_NULL

export clipboard

typealias Atom Culong
typealias Time Culong
typealias X11_Bool Cint
typealias XID Culong

typealias Display Ptr{Void}
typealias _XEvent Ptr{Void}
typealias Window XID

# Useful constants

const COPYBUF_MAX_SZ = 128*1024 # 128K buffer for copying data

const CurrentTime = zero(Clong)
const Success =     int32(0)
const BadRequst =   int32(1)
const BadValue =    int32(2)
const BadWindow =   int32(3)
const BadAtom =     int32(5)

const NoneAtom =    int32(0)

const SelectionNotify = int32(31)
const AnyPropertyType = zero(Atom)

# Event types

abstract XEvent

type XAnyEvent <: XEvent
    _type::Cint
    serial::Culong
    send_event::X11_Bool
    disp::Display
    window::Window

    XAnyEvent(xevent::IOBuffer) = fillXEvent(new(), xevent)
end

type XSelectionEvent <: XEvent
    _type::Cint
    serial::Culong
    send_event::X11_Bool
    disp::Display
    window::Window

    selection::Atom
    target::Atom
    property::Atom 
    time::Time

    XSelectionEvent(xevent::IOBuffer) = fillXEvent(new(), xevent)
end

# Fill in type values from 
function fillXEvent{T<:XEvent}(x::T, xevent::IOBuffer)
    seekstart(xevent)
    p = 0
    for (n,t) in zip(T.names, T.types)
        if t == Ptr{Void}
            x.(n) = pointer(Void, read(xevent, Uint64))
            p += 8
        else
            x.(n) = read(xevent, t)
            p += sizeof(t)
        end
        if p%8 != 0
            read(xevent, Array(Uint8, 8-p%8))
            p += (8-p%8)
        end
    end
    x
end

## Function wrappers
XOpenDisplay(name::String = "")            = ccall((:XOpenDisplay,   :libX11), Display, (Ptr{Void},),    name == "" ? C_NULL : name)
DefaultScreen(disp::Display)               = ccall((:XDefaultScreen, :libX11), Cint,    (Display,),      disp)
RootWindow(disp::Display, screen::Integer) = ccall((:XRootWindow,    :libX11), Window,  (Display, Cint), disp, screen)

XInternAtom(disp::Display, 
            name::ASCIIString, 
            only_if_exists::Bool = false) = 
    ccall((:XInternAtom, :libX11), Atom, (Display, Ptr{Cuchar}, X11_Bool), disp, name, only_if_exists)

XCreateSimpleWindow(disp::Display,
                    parent::Window,
                    x::Integer,
                    y::Integer,
                    width::Integer,
                    height::Integer,
                    border_width::Integer,
                    border::Uint64,
                    background::Uint64) = 
    ccall((:XCreateSimpleWindow, :libX11), Window, 
          (Display, Window, Cint, Cint, Cuint, Cuint,  Cuint,        Culong, Culong),
           disp,    parent, x,    y,    width, height, border_width, border, background)

BlackPixel(disp::Display, screen::Integer) = ccall((:XBlackPixel, :libX11), Culong, (Display, Cint), disp, screen)

XConvertSelection(display::Display,
                  selection::Atom,
                  target::Atom,
                  property::Atom,
                  requestor::Window,
                  time::Integer) =
    ccall((:XConvertSelection, :libX11), Cint, 
          (Display, Atom,      Atom,   Atom,     Window,    Time),
           disp,    selection, target, property, requestor, time)

XFlush(disp::Display) = ccall((:XFlush, :libX11), Cint, (Display,), disp)

# Buffer to pass to XLib
const xevent = IOBuffer(96)

function XNextEvent(disp::Display, xevent::IOBuffer = xevent)
    rv = ccall((:XNextEvent, :libX11), Cint, (Display, _XEvent), disp, xevent.data)

    xevent.size = 96 # this is a lie...
    seekstart(xevent)
    _type = read(xevent, Cint)

    _type == SelectionNotify ? XSelectionEvent(xevent) :
                               XAnyEvent(xevent)
    
end

XFree(p) = ccall((:XFree, :libX11), Cint, (Ptr{Void},), p)

XPending(d::Display) = ccall((:XPending, :libX11), Cint, (Display,), d)

function XGetAtomName(disp::Display, a::Atom)
    if a == NoneAtom
        return "None"
    end
    p = ccall((:XGetAtomName, :libX11), Ptr{Cuchar}, (Display, Atom), disp, a)
    if p == C_NULL
        error("XGetAtomName: BadAtom (Atom does not exist)")
    end
    rv = bytestring(p)
    XFree(p)
    return rv
end

XConnectionNumber(display::Display) = 
   ccall((:XConnectionNumber, :libX11), Cint, (Display,), display)

#

type _Property
    _type           ::Atom
    format          ::Cint
    nitems          ::Culong
    bytes_remaining ::Culong
    data            ::Ptr{Cuchar}
end

function XGetWindowProperty(display     ::Display,
                            w           ::Window,
                            property    ::Atom,
                            long_offset ::Integer,
                            long_length ::Integer,
                            delete      ::Bool,
                            req_type    ::Atom)
    actual_type     = Array(Atom, 1)
    actual_format   = Array(Cint, 1)       # = size in bits of one item of actual_type (8, 16, or 32)
    nitems          = Array(Culong, 1)
    bytes_remaining = Array(Culong, 1)
    prop            = Array(Ptr{Cuchar}, 1)

    rv = ccall((:XGetWindowProperty, :libX11), Cint,
               (Display    , Window       , Atom       , Clong          , Clong      , X11_Bool, Atom    ,
                Ptr{Atom}  , Ptr{Cint}    , Ptr{Culong}, Ptr{Culong}    , Ptr{Ptr{Cuchar}}                ),

                display    , w            , property   , long_offset    , long_length, delete  , req_type,
                actual_type, actual_format, nitems,      bytes_remaining, prop                             )

    if rv != Success
        rv == BadAtom   ? error("XGetWindowProperty: BadAtom") :
        rv == BadValue  ? error("XGetWindowProperty: BadValue") :
        rv == BadWindow ? error("XGetWindowProperty: BadWindow") : 
        error("XGetWindowProperty: Unknown error ($rv)")
    end

    return _Property(actual_type[1], actual_format[1], nitems[1], bytes_remaining[1], prop[1])
end

type Property{T}
    _type           ::Atom
    data            ::Array{T}
end

function GetWindowProperty(display     ::Display,
                           w           ::Window,
                           property    ::Atom,
                           delete      ::Bool = false,
                           req_type    ::Atom = AnyPropertyType)
    buf = Uint8[]
    bufp = 1

    # query size

    prop = XGetWindowProperty(display, w, property, 0, 0, delete, req_type)

    if prop._type == NoneAtom
        @assert prop.bytes_remaining == 0
        @assert prop._type == 0
        error("Requested atom ($(XGetAtomName(disp, req_type)) does not exist")
    end

    if prop._type == XA_ATOM || prop._type == XA_TARGETS
        sz = div(prop.bytes_remaining,(prop.format>>3))*sizeof(Atom)
    else
        sz = prop.bytes_remaining # size in bytes of items read
    end

    # Resize return buffer to correct size in one shot
    if length(buf) < sz
        resize!(buf, sz)
    end

    # Do the actual read

    prop = XGetWindowProperty(display, w, property, 0, sz>>2+1, delete, req_type)

    println("sz = $sz")
    println("bytes remaining = $(prop.bytes_remaining)")
    @assert prop.bytes_remaining == 0

    # Copy the data
    unsafe_copy!(pointer(buf, bufp), prop.data, sz)
    bufp += sz
    XFree(prop.data)

    # Should we convert the buffer here or somewhere else

    if prop.format == 8
        return Property(prop._type, buf)
    elseif prop.format == 16
        return Property(prop._type, reinterpret(Uint16, buf))
    elseif prop.format == 32
        return Property(prop._type, reinterpret(Uint32, buf))
    #elseif prop.format == 64            # This doesn't exist yet...
        #return Property(prop._type, reinterpret(Uint64, buf))
    else
        error("Unknown type size: $prop.format")
    end
end


# Initialization
const disp = XOpenDisplay()
const screen = DefaultScreen(disp)
const root = RootWindow(disp, screen)

# We need a window to exist, but it doesn't have to be visible (mapped)
const w = XCreateSimpleWindow(disp, root, 0, 0, 100, 100, 0, BlackPixel(disp, screen), BlackPixel(disp, screen))

# clipboard related atoms
const sel        = XInternAtom(disp, "CLIPBOARD", false)
const XA_TARGETS = XInternAtom(disp, "TARGETS", false)
const XA_ATOM    = convert(Atom,  4) # Xatom.h
const XA_STRING  = convert(Atom, 31) # Xatom.h

# utility function for converting mime types
string{T}(::Type{MIME{T}}) = string(T)

#
function pick_target_from_list{U<:ByteString}(disp::Display, atom_list::Vector{Atom}, datatypes::Array{U})

    atom_names  = [XGetAtomName(disp, atom)=>atom for atom in atom_list]

    for atom in atom_names
        println(atom)
    end

    for d in datatypes
        if (atom = get(atom_names, d, 0)) > 0
            return atom
        end
    end
    return NoneAtom
end

function pick_target_from_targets{T,U<:ByteString}(disp::Display, p::Property{T}, datatypes::Array{U})
    # work around broken implementations

    if((p._type != XA_ATOM && p._type != XA_TARGETS) || sizeof(T) != 4)
        if "STRING" in datatypes
            return XA_STRING
        else
            return NoneAtom
        end
    end

    return pick_target_from_list(disp, reinterpret(Atom, p.data), datatypes)
end

function clipboard{T<:Union(ByteString,MIME)}(;types::Array{T}=["STRING"])

    datatypes = [string(x) for x in types]

    # Ask for the list of targets for the current item on the clipboard
    XConvertSelection(disp, sel, XA_TARGETS, sel, w, CurrentTime)
    XFlush(disp)

    to_be_requested = NoneAtom
    sent_request = false

    x11_fd = XConnectionNumber(disp)

    while(true)
        # Are any events pending?
        if XPending(disp) == 0
            # poll Xlib with a 2 second timeout)
            if poll_fd(RawFD(x11_fd), 2, readable=true) == 0
                return nothing # timeout
            end
        end

        e = XNextEvent(disp)
        if(e._type == SelectionNotify)  # dispatch based on type instead?

            if e.property == NoneAtom
                return nothing
            end

            prop = GetWindowProperty(disp, w, sel)

            if e.target == XA_TARGETS && !sent_request
                sent_request=true
                to_be_requested = pick_target_from_targets(disp, prop, datatypes)
                if(to_be_requested == NoneAtom)
                    return nothing
                end

                # request the conversion to our preferred datatype
                XConvertSelection(disp, sel, to_be_requested, sel, w, CurrentTime)
                XFlush(disp)

                println("sent request")

            elseif e.target == to_be_requested
                return prop.data
            end
        end
    end
end

#end
