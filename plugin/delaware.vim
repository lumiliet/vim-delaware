
let s:path = expand('<sfile>:p:h')

fun! OnYank()
    echo v:event
    
    let yanklist = s:path .'/../.yanklist'
    if v:event.operator == 'd'
        call writefile(v:event.regcontents, yanklist, "a")
    endif
endf

autocmd TextYankPost * :call OnYank()
