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

Implementation
--------------
In order to cut down on P4 traffic, the plugin only executes three
commands:
- `p4 opened` to get the list of opened files (depot names)
- `p4 client` to get the client view; depot names are translated
to local names by the script, rather than via `p4 where`
- `p4 changes -L -s pending -c <client_name>` to get the first line
of description for each pending change

Notes
-----
- Currently supports UNIX file system paths only.
- Expects `P4USER`, `P4PORT`, `P4CLIENT` to be set (env or `P4CONFIG`)
- Expects `p4` to be in the `PATH`
- Prompts for the P4 password if expired and calls `p4 login`

TODO
----
- Better error handling
- Add documentation
