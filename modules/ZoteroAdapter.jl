function _zotero_get_pdf_path(hashstr::String)
    global SETTING
    pdfdir = _abspath(SETTING["zotero_db_path"], "storage", hashstr)
    fs = readdir(pdfdir)
    ipdf = findfirst(endswith(".pdf"), fs)
    if isnothing(ipdf)
        return ""
    else
        fname = replace(fs[ipdf], " "=>"%20")
        return _abspath(pdfdir, fname)
    end
end
