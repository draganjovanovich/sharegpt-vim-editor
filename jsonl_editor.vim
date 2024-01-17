" JSONL UI ShareGPT Editor Plugin

let g:current_jsonl_line = 1
let g:jsonl_data = []
let g:jsonl_hidden_bufnr = -1
let g:jsonl_ui_bufnr = -1
let g:jsonl_modified = 0


function! LoadJsonlData()
  let g:jsonl_data = readfile(expand('%'))
  let g:jsonl_hidden_bufnr = bufnr('%')

  tabnew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  let g:jsonl_ui_bufnr = bufnr('%')

  file JSONL ShareGPT Editor
  nnoremap <buffer> <silent> <Down> :call JsonlNext()<CR>
  nnoremap <buffer> <silent> <Up> :call JsonlPrevious()<CR>
  nnoremap <buffer> <silent> <F4> :call JsonlSave()<CR>

  autocmd TextChangedI <buffer> let g:jsonl_modified = 1
  let g:jsonl_modified = 0

  call JsonlUIEdit()
  call UpdateSampleDisplay()
endfunction

function! UpdateSampleDisplay()
  let l:sample_info = '< ' . g:current_jsonl_line . ' >'
  call setline(1, l:sample_info)
endfunction

function! JsonlUIEdit()
  execute 'buffer' g:jsonl_ui_bufnr

  if g:current_jsonl_line < 1 || g:current_jsonl_line > len(g:jsonl_data)
    echo "Out of range"
    return
  endif

  let l:line_content = g:jsonl_data[g:current_jsonl_line - 1]
  if l:line_content == ''
    echo "Blank line, not a JSONL entry"
    return
  endif

  try
    let l:json = json_decode(l:line_content)
  catch
    echo "Failed to parse JSONL line"
    return
  endtry

  %delete _
  setlocal wrap
  startinsert!

  let b:jsonl_keys = keys(l:json)

  for key in b:jsonl_keys
    if key == 'conversations'
      " Handle conversations separately
      call append('.', '--- Conversations ---')
      for l:item in l:json['conversations']
        call AppendLinesFromText(l:item['from'], l:item['value'])
      endfor
    else
      call append('.', key . ': ' . l:json[key])
    endif
  endfor

  execute '1'
  stopinsert
endfunction

function! AppendLinesFromText(type, text)
  let l:lines = split(a:text, "\n")
  for l:line in l:lines
    if index(l:lines, l:line) == 0
      call append('$', toupper(a:type) . ': ' . l:line)
    else
      call append('$', repeat(' ', len(toupper(a:type)) + 2) . l:line)
    endif
  endfor
endfunction

function! JsonlSave()
  let g:jsonl_modified = 0

  if mode() == 'i'
    stopinsert
  endif

  let l:json = {}
  let l:current_from = ''
  let l:current_value = ''
  let l:lines = getline(1, '$')

  for key in b:jsonl_keys
    if key == 'conversations'
      let l:json[key] = []
    else
      let l:json[key] = ''
    endif
  endfor

  for l:line in l:lines
    if l:line =~ '^\(SYSTEM\|HUMAN\|GPT\):'
      if l:current_from != ''
        call add(l:json.conversations, {'from': l:current_from, 'value': l:current_value})
        let l:current_from = ''
        let l:current_value = ''
      endif
      let l:current_from = tolower(matchstr(l:line, '^\(SYSTEM\|HUMAN\|GPT\)\ze:'))
      let l:current_value = substitute(l:line, '^\(SYSTEM\|HUMAN\|GPT\):\s*', '', '')
    elseif l:line =~ '^\w\+:'
      let l:parts = split(l:line, ': ', 1)
      let l:key = l:parts[0]
      let l:value = l:parts[1]
      if index(b:jsonl_keys, l:key) != -1
        let l:json[l:key] = l:value
      endif
    else
      if l:current_from != ''
        let l:current_value .= "\n" . substitute(l:line, '\v^' . repeat(' ', len(l:current_from) + 2), '', '')
      endif
    endif
  endfor

  if l:current_from != ''
    call add(l:json.conversations, {'from': l:current_from, 'value': l:current_value})
  endif

  let g:jsonl_data[g:current_jsonl_line - 1] = json_encode(l:json)

  execute 'buffer' g:jsonl_hidden_bufnr
  call setline(1, g:jsonl_data)
  execute 'write! ' . expand('%:p')

  execute 'buffer' g:jsonl_ui_bufnr
  echom "Saved!"
endfunction

function! JsonlNext()
  if g:jsonl_modified
    if confirm("Save changes before moving to the next sample?", "&Yes\n&No", 1) == 1
      call JsonlSave()
    else
      let g:jsonl_modified = 0
    endif
  endif
  if g:current_jsonl_line < len(g:jsonl_data)
    let g:current_jsonl_line += 1
    call JsonlUIEdit()
    call UpdateSampleDisplay()
  else
    echo "No more entries"
  endif
endfunction

function! JsonlPrevious()
  if g:jsonl_modified
    if confirm("Save changes before moving to the next sample?", "&Yes\n&No", 1) == 1
      call JsonlSave()
    else
      let g:jsonl_modified = 0
    endif
  endif
  if g:current_jsonl_line > 1
    let g:current_jsonl_line -= 1
    call JsonlUIEdit()
    call UpdateSampleDisplay()
  else
    echo "No previous entries"
  endif
endfunction

augroup jsonl_ui_editor
  autocmd!
  autocmd BufRead,BufNewFile *.jsonl call LoadJsonlData()
  autocmd BufEnter * if bufnr('%') == g:jsonl_ui_bufnr | command! -buffer W :call JsonlSave() | endif
augroup END

augroup jsonl_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.jsonl setlocal filetype=jsonl
augroup END

" Disable default syntax highlighting for jsonl files
"augroup jsonl_syntax_off
  "autocmd!
  "autocmd BufRead,BufNewFile *.jsonl setlocal syntax=off
"augroup END

augroup jsonl_custom_highlight
  autocmd!
  autocmd FileType jsonl call JsonlCustomHighlight()
augroup END


function! JsonlCustomHighlight()
  if &filetype != 'jsonl'
    return
  endif

  syntax clear

  syntax match jsonlSystemKeyword /^SYSTEM:/ containedin=jsonlSystem
  syntax match jsonlHumanKeyword /^HUMAN:/ containedin=jsonlHuman
  syntax match jsonlGPTKeyword /^GPT:/ containedin=jsonlGPT

  syntax region jsonlSystem start=/^SYSTEM:/ end=/^\(HUMAN:\|GPT:\|SYSTEM:\)\@=/me=e-1,he=e-1
  syntax region jsonlHuman start=/^HUMAN:/ end=/^\(HUMAN:\|GPT:\|SYSTEM:\)\@=/me=e-1,he=e-1
  syntax region jsonlGPT start=/^GPT:/ end=/^\(HUMAN:\|GPT:\|SYSTEM:\)\@=/me=e-1,he=e-1

  highlight jsonlSystemKeyword cterm=bold ctermfg=White ctermbg=Green gui=bold guifg=#FFFFFF guibg=#008000
  highlight jsonlHumanKeyword cterm=bold ctermfg=White ctermbg=Yellow gui=bold guifg=#000000 guibg=#FFD700
  highlight jsonlGPTKeyword cterm=bold ctermfg=White ctermbg=Blue gui=bold guifg=#000000 guibg=#88A3FD

  highlight jsonlSystem cterm=bold ctermbg=106 gui=italic guifg=#aaffbb
  highlight jsonlHuman cterm=bold ctermbg=190 gui=italic guifg=#FBBF24
  highlight jsonlGPT cterm=bold ctermbg=75 gui=italic guifg=#88A3FD
  set spell!
endfunction

if exists(':CocConfig')
  autocmd FileType jsonl :CocDisable
endif
