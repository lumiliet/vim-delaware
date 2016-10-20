

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

    let newHistory = []

    for index in lineRange
        let lines = history[index:index + deletedlength - 1]
        if lines != a:deleted
            let newHistory = newHistory + lines
        endif
    endfor
    let deletedStart = max([deletedlength - g:delaware_maximum_history_length, 0])
    let combined = newHistory + map(a:deleted[deletedStart:], "v:key . ':' . v:val")

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

fun! s:Insert(text)
    " set modifiable
    call s:Delete('%')
    call append('0', a:text)
    call s:Delete('$')
    " set nomodifiable
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



