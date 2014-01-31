module XClipboard

import Base.Multimedia.@textmime
export xclipboard, xclipboard_MIME_targets, decodemime

include("XLib.jl")
include("xmime.jl")

# Get a list of clipboard targets, as X11 Atoms
function xclipboard_targets(timeout::Int=2)

    data = xclipboard_request(XA_TARGETS, timeout)
    return reinterpret(Atom, data)
end

# Get a list of clipboard targets as "MIME" types
# (Note that most of the returned types are typically not true MIME types)
xclipboard_MIME_targets(timeout::Int=2) = xclipboard_MIME_targets(xclipboard_targets(timeout))
xclipboard_MIME_targets(targets::Array{Atom}) = [MIME(XGetAtomName(atom)) for atom in targets]

function xclipboard{T}(mimetype::MIME{T}, timeout::Int=2)

    atoms = xclipboard_targets(timeout)
    atom_d = Dict(xclipboard_MIME_targets(atoms), atoms)
    request_atom = atom_d[mimetype]

    data = xclipboard_request(request_atom, timeout)

    return decodemime(mimetype, data)
end

xclipboard() = xclipboard(MIME("UTF8_STRING"))

end # module
