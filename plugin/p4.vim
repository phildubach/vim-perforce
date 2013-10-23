" Functions to create a new scratch window listing all open files
" grouped by change. The file names are in local format to allow
" jumping to the files in vim easily (e.g. gf)
"
" Creates two mappings:
" <leader>po : Gets information about opened files from P4 and
"              displays it in a named scratch window
" <leader>pp : Switches to the previously created scratch window,
"              if it exists, otherwise gets the info from P4

" set to 1 to enable debugging echoes
let s:debug = 0

function! s:Log(str)
    if s:debug
        echo a:str
    endif
endfunction

function! s:P4(args)
    let reply = system('p4 ' . a:args)
    if v:shell_error
        if reply =~# '^Your session' || reply =~# '^Perforce password'
            let passwd = inputsecret('Perforce password: ')
            let reply = system('p4 login', passwd)
            if v:shell_error
                echoerr 'P4 login failed'
                echoerr reply
                throw "P4LoginFailed"
            else
                " Call ourselves after successful login
                return <SID>P4(a:args)
            endif
        else
            echoerr 'Command failed: p4 ' . a:args
            echoerr reply
            throw "P4Error"
        endif
    endif
    return reply
endfunction

function! s:P4opened()
    " get the list of opened depot files
    let opened=<SID>P4('opened')
    let files = split(opened, '\v\n')
    call <SID>Log(files)

    " get the client description and extract the view mappings
    let lines = split(<SID>P4('client -o'), '\v\n')
    call <SID>Log(lines)
    let viewSeen = 0
    let view = {}
    for line in lines
        let match = matchlist(line, '\v^Client:\s+(.*)$')
        if !empty(match)
            let client = match[1]
        endif
        let match = matchlist(line, '\v^Root:\s+(.*)$')
        if !empty(match)
            let root = match[1]
        endif
        if line =~# '\v^View:\s*$'
            let viewSeen = 1
        endif
        let match = matchlist(line, '\v\s+(//.*)\.\.\.\s+(//.*)\.\.\.\s*$')
        if viewSeen && !empty(match)
            let src = match[1]
            let tgt = substitute(match[2], '^//' . client, root, '')
            let view[match[1]] = tgt
        endif
    endfor
    call <SID>Log(client)

    " map the opened depot files to local files
    " The longest match wins, so reverse sort the keys
    let folders = reverse(sort(keys(view)))
    let localFiles = []
    for openFile in files
        let found = 0
        for key in folders
            if openFile =~# '^' . key
                let localFile = substitute(openFile, '^' . key, view[key], '')
                let localFiles = add(localFiles, localFile)
                call <SID>Log(localFile)
                let found = 1
                break
            endif
        endfor
        if !found
            echoerr "No mapping found for " . openFile
        endif
    endfor

    " parse the p4opened strings and order files by change
    let changes = {}
    for localFile in localFiles
        " \1: file name; \2: action; \3: "default"? \4: change number; \5: rest (filetype)
        let match = matchlist(localFile, '\v^([^#]*)#\d+\s+-\s+(\a+)\s+%(%((default) change)|%(change\s+(\w+)))\s+(.*)')
        call <SID>Log(match)
        if !empty(match)
            let changeNum = match[4] ? match[4] : match[3]
            let openFiles = get(changes, changeNum, [])
            let openFiles = add(openFiles, match[1] . ' - ' . match[2] . ' ' . match[5])
            let changes[changeNum] = openFiles
        endif
    endfor

    " get list of change titles for pending changes in this client
    let titles = {}
    let descriptions = split(<SID>P4('changes -L -s pending -c ' . client), '\v\n')
    for description in descriptions
        let match = matchlist(description, '\v^Change (\d+) on')
        if !empty(match)
            let chg = match[1]
        elseif description =~ '\v^\t\s*'
            let titles[chg] = substitute(description, '\v\t\s*', '', '')
        endif
    endfor

    " print opened files grouped by changes into lines
    let lines=[]
    for chg in sort(keys(changes))
        let lines = add(lines, chg . ': ' . get(titles, chg, ''))
        let openFiles = changes[chg]
        for openFile in openFiles
            let lines = add(lines, '  ' . openFile)
        endfor
        let lines = add(lines, '')
    endfor

    " display the lines in a new vsplit
    let bn = bufnr("__P4_opened__", 1)
    if bn != -1
        execute 'buffer ' . bn
        " double check we've switched to the buffer
        if bufname("%") == "__P4_opened__"
            normal! gg"_dG
            setlocal filetype=p4opened
            setlocal buftype=nofile
            setlocal bufhidden=hide
            syntax keyword p4ChangeKeyword add edit integrate delete
            highlight link p4ChangeKeyword Keyword
            syntax match p4ChangeTitle /\v.*/ms=s+2 contained
            highlight link p4ChangeTitle TabLine
            syntax match p4ChangeNumber /\v^\w+\ze: / contained
            highlight link p4ChangeNumber Number
            syntax match p4ChangeLine /\v^\w+: .*/ contains=p4ChangeNumber,p4ChangeTitle
            syntax match p4ChangeFile /\v^  \/[^ ]+/
            highlight link p4ChangeFile Identifier
            call append(0, lines)
        else
            echo bufname("%")
        endif
    endif
endfunction

function! s:P4showOpened()
    let bn = bufnr("__P4_opened__")
    if bn == -1
        " query P4 and create the buffer
        call <SID>P4opened()
    else
        " show existing buffer
        execute 'buffer ' . bn
    endif
endfunction

nnoremap <leader>po :call <SID>P4opened()<CR>
nnoremap <leader>pp :call <SID>P4showOpened()<CR>
