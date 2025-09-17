#  TODO

- maybe use "apply" as a screenshot
- clear the last man search, and restore it after it has finished rendering successfully
- for all those weird special casings for existing man pages -- have a mode to produce a list of warnings and suggestions to improve quality of man pages.

* the SYNOPSIS section should hanging indent the definition of the function if it is too long.  Or treat is a two column table with the name in the first column and the definition in the second (like a .Bl).  Noticed on man install

# Bad man source

* man avmediainfo has a .Bl error -- it is in the source -- there is a missing .Bd

# BUGS

- invalid man pages no longer display the error message (this is a reversion)

- man page for awk  looks fixed -- but there is too much whitespace near the beginning of DESCRIPTION

- man page for c++ does not render properly -- .TP right justifying sometimes.

- legacy display always displays error: no manual entry for /

- man captoinfo fails because it uses .TS -- the tbl processor

- man dyld-usage defines macros INDENT and UNIDENT -- then processes them wrong in the OPTIONS section

- man funzip (excessive whitespace in EXAMPLES)


- LEGACY mode fails on man jq -- it terminates reading the stdout too soon -- borrow the code from ShellTesting .  Noticed because the BUGS section has an extra final dot in the render.

- man ksh (contents of NAME missing)

- man less fails because the file is less.1.gz -- need to be able to handle compressed man files.  Also true for lessecho and lesskey and more

- man nslookup    (conditionals make everything disappear)

- man 1 ssh-copy-id  uses a .ig macro which is not implemented.

- man 1 tclsh, tkcon, (just that one weird } hanging out in SYNOPSIS -- plus too much white space) wish (options are super way indented)

- man 1 xmlcatalog and xmllint and xsltproc  loses it in SEE ALSO  -- xsltproc also has weirdness following -o

- man 1 zipgrep : the description of   pattern   is wrong -- and it eats file[.zip] -- so problem with .IR ?  or .IP?

- man 1 zipinfo : DETAILED DESCRIPTION :  defined options take arguments ($1, etc)



==========> zsh man pages
- man 1 zshbuiltins : indentation and list handling seems wrong -- is the problem ".PD" ??

- man 1 zshcompsys : that first list has a bullet in totally the wrong place.

- man 1 zshcompwid : list bullet placement 

- the zxh functions often have the first element of a list misformatted -- but that may be due to the source 

- man 1 zshmisc -- the indentation seems wonky

- man 1 zshmodules -- the first element of most lists seems wrong. just all the zsh\* man pages have this problem.

============> perl man pages

- man lsm, net-server fail to render properly

- perlutil (maybe other perl\*), pod2readme (options are missing), pod2usage (why so much indent)
 
- more perldoc mans:  streamzip, xgettext.pl, zipdetails


