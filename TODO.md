#  TODO

- maybe use "apply" as a screenshot
- clear the last man search, and restore it after it has finished rendering successfully
- for all those weird special casings for existing man pages -- have a mode to produce a list of warnings and suggestions to improve quality of man pages.

* the SYNOPSIS section should hanging indent the definition of the function if it is too long.  Or treat is a two column table with the name in the first column and the definition in the second (like a .Bl).  Noticed on man install

# Bad man source

* man avmediainfo has a .Bl error -- it is in the source -- there is a missing .Bd

# BUGS

- invalid man pages no longer display the error message (this is a reversion)

- man page for c++ does not render properly -- .TP right justifying sometimes.

- legacy display always displays error: no manual entry for /

- man captoinfo fails because it uses .TS -- the tbl processor

- man funzip (excessive whitespace in EXAMPLES)


- LEGACY mode fails on man jq -- it terminates reading the stdout too soon -- borrow the code from ShellTesting .  Noticed because the BUGS section has an extra final dot in the render.

- man less fails because the file is less.1.gz -- need to be able to handle compressed man files.  Also true for lessecho and lesskey and more

- man nslookup    (conditionals make everything disappear)

- man 1 xmlcatalog and xmllint and xsltproc  loses it in SEE ALSO  -- xsltproc also has weirdness following -o

- man 1 zipgrep : the description of   pattern   is wrong -- and it eats file[.zip] -- so problem with .IR ?  or .IP?

- man 1 zipinfo : DETAILED DESCRIPTION :  defined options take arguments ($1, etc)

====================================

- man 2 chown : too many "<br> s" in SYNOPSIS?

- 2 FD_CLR  (. Fc ;  fas a carriage return)

- 2 fsetattrlist : does the EXAMPLe need more whitespace to start at the Bd -literal

- 2 settimeofday : .Ao Pa sys/time.h Ac -- the closing angle bracket is colored, and there is an extra blank after .h

=====================================

- 3 add_module_replacement : ENVIRONMENT VARIABLES indent too much (.IP problem)
- 3 add_wch : uses tbl processor
- 3 Algorithm::Annotate -- Perl documentation
- 3 aliased -- tricky Perl  -- the definition .ds #H ...  was the problem
- 3 Apache2::Access -- Perl prelude
- 3 Apache2::CmdParms, Apache2::Command

