# X "mime" types

# These are possible return types from the X11 clipboard which are not
# actual MIME types (for the most part), but which are text and can be
# treated as such.

for mime in ["STRING", "UTF8_STRING", "text/plain;charset=utf-8", "text/plain;charset=UTF-8", "TEXT", "COMPOUND_TEXT"]
    @eval @textmime $mime
    @eval decodemime(m::MIME{symbol($mime)}, x) = bytestring(x)
end

for mime in ["text/vnd.graphviz", "text/latex", "text/calendar", "text/n3", "text/richtext", "text/x-setext", "text/sgml", "text/tab-separated-values", "text/x-vcalendar", "text/x-vcard", "text/cmd", "text/css", "text/csv", "text/html", "text/javascript", "text/plain", "text/vcard", "text/xml", "application/atom+xml", "application/ecmascript", "application/json", "application/rdf+xml", "application/rss+xml", "application/xml-dtd", "application/postscript", "image/svg+xml", "application/x-latex", "application/xhtml+xml", "application/javascript", "application/xml", "model/x3d+xml", "model/x3d+vrml", "model/vrml"]
    @eval decodemime(m::MIME{symbol($mime)}, x) = bytestring(x)
end

decodemime(m::MIME, x) = x