" Detect a Perforce change description being opened and set
" noexpandtab, since the description needs to be indented
" with tabs, otherwise Perforce adds the tabs itself
if !did_filetype()
    if getline(1) =~ '^# A Perforce Change'
        set noexpandtab
	endif
endif
