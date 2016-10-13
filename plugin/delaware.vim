
let s:pluginPath = expand('<sfile>:p:h')

if !exists('s:ranOnce')
    autocmd TextYankPost * :call s:OnDelete()
    autocmd BufHidden * :call s:OnHiddenBuffer()

    let s:ranOnce = 1
endif

com! Delaware :call s:Delaware()


fun! s:OnDelete()
    let historyFile = s:GetHistoryFile()
    if v:event.operator == 'd' && len(historyFile) && len(join(v:event.regcontents, ''))
        call writefile(v:event.regcontents, historyFile, "a")
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

fun! s:ReadHistory()
    let historyFile = s:GetHistoryFile()
    if filereadable(historyFile)
        return readfile(historyFile)
    else
        return ""
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
    if !exists('b:delawareBufferNumber')
        call s:SetupWindow()
    endif

    call s:Insert(a:history)
endf


fun! s:SetupWindow()
    let filetype = &filetype
    :split
    normal J
    :resize 10
    :set wfh
    :enew
    :set buftype=nowrite
    exec "set filetype=" . filetype
    let b:delawareBufferNumber = bufnr('%')

endf

fun! s:OnHiddenBuffer()
    if exists('b:delawareBufferNumber')
        exec b:delawareBufferNumber . "bd"
    endif
endf
