# os2_game1src_fpc
OS/2 DIVE demonstrator

# Original source
game1src (EDM2)

# Compilation
Using fpc 3.2.2 or later.

fpc -Fuunits -Iinc game1

Resource file (as needed): RC -r GAME1.RC.  

The src directory has a makeme.cmd file which assumes the ToolKit to be installed. If this is not the case you can remove the os2.h include from the .RC file


# Credits
Michael T. Duffy for his code and publication (EDM2 site)
