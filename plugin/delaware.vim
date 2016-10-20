fun! s:InitializeSettings()
    if !exists('g:delaware_maximum_history_length')
        let g:delaware_maximum_history_length = 1000
    endif

    if !exists('g:delaware_minimum_text_length')
        let g:delaware_minimum_text_length = 5
    endif
endf

if !exists('s:ranOnce')
    autocmd TextYankPost * :call s:OnDelete()
    autocmd BufHidden * :call s:OnHiddenBuffer()
    autocmd BufEnter * :call s:RefreshInDelaware()

    let s:ranOnce = 1
    let s:pluginPath = expand('<sfile>:p:h')

    call s:InitializeSettings()

    com! Delaware :call s:Delaware()
    com! DelawareCleanOne :call s:CleanHistoryFile()
    com! DelawareCleanAll :call s:CleanAllHistoryFiles()
endif


fun! s:OnDelete()
    if (v:event.operator == 'c' || v:event.operator == 'd')
        call s:InsertIntoHistory(v:event.regcontents)
    endif
endf

fun! s:InsertIntoHistory(deleted)

    if len(join(a:deleted, '')) < g:delaware_minimum_text_length
        return
    endif

    let history = s:ReadHistory()

    let deletedlength = len(a:deleted)
    let historyLength = len(history)

    let historyStart = max([historyLength - g:delaware_maximum_history_length + deletedlength, 0])
    let historyEnd = max([historyLength - deletedlength, historyStart])
    let lineRange = range(historyStart, historyEnd, deletedlength)

    let deletedLines = a:deleted[max([deletedlength - g:delaware_maximum_history_length, 0]):]
    let deletedLines = map(s:Trim(deletedLines), "v:key . ':' . v:val")

    call s:WriteToHistory(s:RewriteHistory(history, deletedLines))
endf

fun! s:Trim(lines)
    let emptyLinesFront = 0
    let emptyLinesBack = 0

    for index in range(0, len(a:lines) -1)
        if a:lines[index] == ''
            let emptyLinesFront = emptyLinesFront + 1
        else
            break
        endif
    endfor

    for index in range(len(a:lines) - 1, 0, -1)
        if a:lines[index] == ''
            let emptyLinesBack = emptyLinesBack + 1
        else
            break
        endif
    endfor

    return a:lines[emptyLinesFront: len(a:lines) - emptyLinesBack - 1]
endf

fun! s:RewriteHistory(history, deletedLines)
    let rewrittenHistory = []
    let chunks = s:ChunkHistory(a:history)

    for chunk in chunks
        if chunk != a:deletedLines
            for line in chunk
                call add(rewrittenHistory, line)
            endfor
        endif
    endfor

    return rewrittenHistory + a:deletedLines
endf

fun! s:ChunkHistory(history)
    let chunks = []
    let history = a:history

    while len(history)
        let chunk = s:GetChunk(history)
        let history = history[len(chunk):]
        call add(chunks, chunk)
    endw

    return chunks
endf

fun! s:GetChunk(history)
    let chunk = []

    for line in a:history
        let decoded = s:DecodeHistoryLine(line)

        if len(chunk) && decoded["number"] == 0
            return chunk
        else
            call add(chunk, line)
        endif
    endfor

    return chunk
endf

fun! s:DecodeHistoryLine(line)
    let match = matchlist(a:line, '^\([0-9]*\):')
    if len(match)
        let number = match[1]
        let line = a:line[len(number) + 1:]
        return {"number": number, "line": line}
    else
        return false
    endif
endf

fun! s:WriteToHistory(list)
    let historyFile = s:GetHistoryFile()
    if len(historyFile)
        call writefile(a:list, historyFile)
    endif
endf

fun! s:GetHistoryFile()
    let filename = substitute(expand('%:p'), '/', '%', 'g')
    if len(filename)
        return s:GetHistoryDirectory() . filename
    else
        return ""
    endif
endf

fun! s:GetHistoryDirectory()
    return s:pluginPath .'/../history/'
endf

fun! s:ReadHistory(...)
    let historyFile = s:GetHistoryFile()

    if a:0 == 1
        let historyFile = a:1
    endif

    if filereadable(historyFile)
        return readfile(historyFile)
    else
        return []
    endif
endf


fun! s:RefreshInDelaware()
    if exists('b:delawareHistoryFile')
        let history = s:ReadHistory(b:delawareHistoryFile)
        call s:Insert(history)
    endif
endf

fun! s:Delete(range)
    exec "silent " . a:range . "delete _"
endf

fun! s:Insert(history)
    let formatted = FormatHistory(a:history)
    set modifiable
    call s:Delete('%')
    call append('0', formatted)
    call s:Delete('$')
    set nomodifiable
endf

fun! FormatHistory(history)
    let formatted = []

    let chunks = s:ChunkHistory(a:history)

    let previousLength = 1

    for chunk in chunks
        let length = len(chunk)

        if length > 1 || previousLength != 1
            call add(formatted, "")
        endif

        for line in chunk
            call add(formatted, s:DecodeHistoryLine(line)["line"])
        endfor

        let previousLength = length
    endfor

    return s:Trim(formatted)
endf

fun! s:Delaware()
    let history = s:ReadHistory()

    if !len(history)
        let filename = expand('%')
        if len(filename)
            echo "No Delaware history for " . filename
        else
            echo "Delaware history not available"
        endif
    else
        call s:CreateDelaware(history)
    endif
endf

fun! s:CreateDelaware (history)
    if !exists('b:delawareHistoryFile')
        call s:SetupWindow()
    endif

    call s:Insert(a:history)
endf


fun! s:SetupWindow()
    let historyFile = s:GetHistoryFile()
    let filetype = &filetype
    :split
    normal J
    :resize 15
    :set wfh
    :enew
    :set buftype=nowrite
    exec "set filetype=" . filetype
    let bufferNumber = bufnr('%')
    let b:delawareBufferNumber = bufferNumber
    let b:delawareHistoryFile = historyFile
endf

fun! s:OnHiddenBuffer()
    if exists('b:delawareHistoryFile')
        exec b:delawareBufferNumber . "bd"
    endif
endf

fun! s:CleanHistoryFile()
    let historyFile = s:GetHistoryFile()
    if len(historyFile)
        call delete(historyFile)
    elseif exists('b:delawareHistoryFile')
        call delete(b:delawareHistoryFile)
        :q
    else
        echo "Nothing to delete"
    endif
endf

fun! s:CleanAllHistoryFiles()
    let directory = s:GetHistoryDirectory()
    let files = split(globpath(directory, '*'))
    for file in files
        call delete(file)
    endfor
    if exists('b:delawareHistoryFile')
        :q
    endif
    if len(files)
        echo "All clean"
    else
        echo "Nothing to delete"
    endif
endf


