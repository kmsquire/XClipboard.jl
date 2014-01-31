module XClipboard

import Base.Multimedia.@textmime
export xclipboard, xclipboard_targets, decodemime

include("XLib.jl")
include("xmime.jl")

# Get a list of clipboard targets, as X11 Atoms
xclipboard_target_atoms(timeout::Int=2) = 
    reinterpret(Atom, xclipboard_request(XA_TARGETS, timeout))

# Get a list of targets as MIME types
xclipboard_targets(targets::Array{Atom}) = 
    [MIME(XGetAtomName(atom)) for atom in targets]
xclipboard_targets(timeout::Int=2) = 
    xclipboard_targets(xclipboard_target_atoms(timeout))

# Get a Dict of clipboard targets as (MIME_type => Atom)[]
function xclipboard_targets_atoms(timeout::Int=2)
    atoms = xclipboard_target_atoms(timeout)
    return Dict(xclipboard_targets(atoms), atoms)
end

# Main xclipboard function
function xclipboard(mimetypes::Array{MIME}, timeout::Int=2)

    atoms = xclipboard_targets_atoms(timeout)
    local request_atom, mimetype
    for mimetype in mimetypes
        if (request_atom = get(atoms, mimetype, NoneAtom)) != NoneAtom
            break
        end
    end

    if request_atom == NoneAtom
        error("Requested clipboard target(s) not found.")
    end

    data = xclipboard_request(request_atom, timeout)

    return decodemime(mimetype, data)
end
xclipboard(mimetype::MIME, timeout::Int=2) = xclipboard([mimetype], timeout)
xclipboard(mimetype::String...) = xclipboard([MIME(m) for m in mimetype])
xclipboard() = xclipboard("UTF8_STRING", "STRING", "TEXT")

end # module
