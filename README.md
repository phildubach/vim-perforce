vim-perforce
============

Tools for Perforce integration

Builds a list of the current client's opened files and
displays them in a scratch buffer, grouped by change.

Creates two mappings:

- `<leader>po`:  Gets information about opened files from P4 and
displays it in a named scratch window
- `<leader>pp`: Switches to the previously created scratch window,
if it exists, otherwise gets the info from P4

Notes
-----
- Currently supports UNIX file system paths only.
- Expects `P4USER`, `P4PORT`, `P4CLIENT` to be set (env or `P4CONFIG`)
- Prompts for the P4 password if expired and calls `p4 login`

TODO
----
- _default_ changelist seems to be missing
- Better error handling
- Add documentation
