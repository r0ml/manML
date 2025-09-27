#  TODO


- maybe use "apply" as a screenshot
- clear the last man search, and restore it after it has finished rendering successfully
- for all those weird special casings for existing man pages -- have a mode to produce a list of warnings and suggestions to improve quality of man pages.
- maybe add a toggle to allow trying to render in troff mode instead of nroff mode (even groff)

* the SYNOPSIS section should hanging indent the definition of the function if it is too long.  Or treat is a two column table with the name in the first column and the definition in the second (like a .Bl).  Noticed on man install

- the back button only goes back 1, then cycles

# Bad man source

* man avmediainfo has a .Bl error -- it is in the source -- there is a missing .Bd

# BUGS

- man page for c++ does not render properly -- .TP right justifying sometimes.

- man captoinfo fails because it uses .TS -- the tbl processor

- man funzip (excessive whitespace in EXAMPLES)

- sometimes, when .nf or Bd -literal, there is too much whitespace if I append the \n at the end of the line -- hosts.equiv shows the problem with EXAMPLES being turned into pre

- LEGACY mode fails on man jq -- it terminates reading the stdout too soon -- borrow the code from ShellTesting .  Noticed because the BUGS section has an extra final dot in the render.

- man less fails because the file is less.1.gz -- need to be able to handle compressed man files.  Also true for lessecho and lesskey and more

- man nslookup    (conditionals make everything disappear)

- man 1 xmlcatalog and xmllint and xsltproc  loses it in SEE ALSO  -- xsltproc also has weirdness following -o

- man 1 zipgrep : the description of   pattern   is wrong -- and it eats file[.zip] -- so problem with .IR ?  or .IP?

- man 1 zipinfo : DETAILED DESCRIPTION :  defined options take arguments ($1, etc)

- 1 xmllint : for \h'-04'...

====================================

- man 2 chown : too many "<br> s" in SYNOPSIS?

- 2 FD_CLR  (. Fc ;  fas a carriage return)

- 2 fsetattrlist : does the EXAMPLe need more whitespace to start at the Bd -literal

- 2 settimeofday : .Ao Pa sys/time.h Ac -- the closing angle bracket is colored, and there is an extra blank after .h

=====================================

- 3 add_module_replacement : ENVIRONMENT VARIABLES indent too much (.IP problem)
- 3 aliased -- tricky Perl  -- the definition .ds #H ...  was the problem
- 3 ckalloc -- tricky Tcl -- typesetting of ARGUMENTS is wrong.

- 3 endwin -- the 'IP \(bu 4'  should indent the bullets by 4ch

======================================

- 4 domainsid : the redirect is to a specific directory, not a relative directory

- 5 classes.conf: need to change the way escape sequences are processed to support both \(co and \[co]   using the regex from   replaceRegisters

- 5 cryptex -- blows up on tbl processing

- 5 launchd.plist -- has many BL Errors -- I made -ohang = -hang -- but the -ohang doesn't indent the tags.

- 5 pcap-savefile -- there's a tbl which should draw boxes -- doesn't format properly

- is there a race when I try to open a new man page while a previous one is still rendering?
