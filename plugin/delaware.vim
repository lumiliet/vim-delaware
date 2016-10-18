
let s:pluginPath = expand('<sfile>:p:h')

if !exists('s:ranOnce')
    autocmd TextYankPost * :call s:OnDelete()
    autocmd BufHidden * :call s:OnHiddenBuffer()
    autocmd BufEnter * :call s:RefreshInDelaware()

    let s:ranOnce = 1
endif

com! Delaware :call s:Delaware()

fun! s:OnDelete()
    if (v:event.operator == 'c' || v:event.operator == 'd') && len(join(v:event.regcontents, ''))
        call s:InsertIntoHistory(v:event.regcontents)
    endif
endf

fun! s:InsertIntoHistory(deleted)
    let history = s:ReadHistory()

    let deletedlength = len(a:deleted)
    let historyLength = len(history)

    let lineRange = range(0,max([historyLength - deletedlength, 0]), deletedlength)

    let newHistory = []
    for index in lineRange
        let lines = history[index:index + deletedlength - 1]
        if lines != a:deleted
            let newHistory = newHistory + lines
        endif
    endfor
    let combined = newHistory + a:deleted

    call s:WriteToHistory(combined)
endf

fun! s:WriteToHistory(list)
    let historyFile = s:GetHistoryFile()
    if len(historyFile)
        call writefile(a:list, historyFile)
    endif
endf

fun! s:GetHistoryFile()
    let filename = substitute(expand('%:p'), '/', '%', 'g')
    let absolutePath = s:pluginPath .'/../history/' . filename
    if len(filename)
        return absolutePath
    else
        return ""
    endif
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
        call s:Delete('%')
        let history = s:ReadHistory(b:delawareHistoryFile)
        call s:Insert(history)
    endif
endf

fun! s:Delete(range)
    exec "silent " . a:range . "delete _"
endf

fun! s:Insert(text)
    call append('0', a:text)
    call s:Delete('$')
endf

fun! s:Delaware()
    let history = s:ReadHistory()

    if !len(history)
        echo "No Delaware history for " . expand('%')
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
    :resize 10
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

fun! s:RefreshOutsideDelaware()
    "Does not work. Cannot switch buffer from autocommand
    if exists('b:delawareBufferNumber')
        exec b:delawareBufferNumber . "b"
        call s:RefreshInDelaware()
        normal 
    endif
endf

