#vim-delaware

Keeps a history of all deleted text for the current file.

##Commands

### `:Delaware`

Bring up the history window.

### `:DelawareCleanOne`

Delete the history file for the current buffer.

### `:DelawareCleanAll`

Delete all history files.


##Options

### `g:delaware_maximum_history_length`

Maximum length of history per file. Default is 1000.

```shell
let g:delaware_maximum_history_length=500
```

### `g:delaware_minimum_text_length`

Minimum length of deleted text for it to be saved. Default is 5 characters.

```shell
let g:delaware_minimum_text_length=10
```


