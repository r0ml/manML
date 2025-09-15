#  TODO

- maybe use "apply" as a screenshot
- clear the last man search, and restore it after it has finished rendering successfully
- for all those weird special casings for existing man pages -- have a mode to produce a list of warnings and suggestions to improve quality of man pages.

# BUGS

- man page for awk does not render properly
- man page for c++ does not render properly
- ssh   (-D [bind_address:port] -- loses is because macroblock starts mid-line (twice) for Xo and Oo
- the places where safify needs to be called need to be identified.  Currently, there are places where it needs to be called and isn't.

- in man arch, need to do for .Bd/.Ed what I did for .Bl/.El

- man avmediainfo has a .Bl error -- it is in the source -- there is a missing .Bd

- man binhex.pl fails because it misparses: ds C' ""  -- which has a carriage return and continues onto the next line.  This is a standard
   prefix for perl documentaion -- and so I expect it will cause all Perl docs to fail.
   Also, the definition for Vb seems to have worked -- but the substitution does not process the .tm and the .ft as macros.
   
- man captoinfo fails because it uses .TS -- the tbl processor

- man config_data, corelist, cpan, dbicadmin, dbilogstrip, dbiprof, dbiproxy, debinhex.pl ... fail because they are perl docs

- man dig has a problem with  .if  macro.

- man dyld-usage defines macros INDENT and UNIDENT -- then processes them wrong in the OPTIONS section

- man enc2xs, encguess, eyapp, findrule, h2ph, h2xs, htmltree, instmodsh, ip2cc, jsonpp, json_xs fail to render properly (they are perldoc))

- man funzip renders the Example section improperly -- it defines macros  EE  and    EX -- performs the substitution when invoked -- but fails to evaluate the substituted macros.

- the SYNOPSIS section should hanging indent the definition of the function if it is too long.  Or treat is a two column table with the name in the first column and the definition in the second (like a .Bl).  Noticed on man install

- LEGACY mode fails on man jq -- it terminates reading the stdout too soon -- borrow the code from ShellTesting .  Noticed because the BUGS section has an extra final dot in the render.

- man ksh doen't handle the roff prelude definitions properly -- looks like a mess.

- man ktrace has many .Bl errors.  Also,  .It Nm Cm info  does not display the Nm.  It defines (.de) trace-opts, then doesn't evaluate it properly.

- man less fails because the file is less.1.gz -- need to be able to handle compressed man files.  Also true for lessecho and lesskey and more

- man libnetcfg, lsm, lwp-download, lwp-dump, lwp-mirror, lwp-request, macerror, net-server fail to render properly (they are perldoc))

- man mailq (and sendmail) is a mess.

- man mdimport has Bl errors for  .Bd -literal

- man nslookup    ARGUMENTS render incorrectly

- man package-stack-conflicts, par.pl, parl, perl fail to render properly (they are perldoc))

- man patch  fails to render  .Qo and .Qc

- all the perl\* (and there are many) fail to render properly (they are perldoc))

- man piconv, pl2pm fail to render properly (they are perldoc))

- man plockstat renders improperly (Options list descriptions not aligned)  Highlights that TP should be handled like .Bl to align columns. 

- all the pod\* ( and there are many) fail to render properly (they are perldoc)
 
- man 5 postconf -- weird indents in SEE ALSO and AUTHORS

- more perldoc mans:  pp, prove, ptar, say, scandeps, shasum, spfd, spfquery, splain, streamzip, tidy_changelog, tkpp, treereg, xgettext.pl, xpath, xsubpp, yapp, zipdetails

- man 1 screen -- .ds shmutz at the beginning

- man 1 snmp-bridge-mib  fails to parse  .RS 4 

- man 1 ssh-agent hung on a thread/race error.  Retry got rid of it.  But something to watch for

- man 1 ssh-copy-id  uses a .ig macro which is not implemented.

- man 1 tailspin is a complete mess -- multiple errors

- man 1 tclsh, tkcon, wish  is also a mess -- but it looks like a perl type mess

- man 1 tcpdump SYNOPSIS is a mess

- man 1 torque has a bunch of /" visible -- which should not be?

- man 1 troptoemail -- complete mess

- man 1 units:  the Bl errors happen weirdly.  The line "memory for prefixes exceeded ends early.  Is this a race? -- probably need to do for .Bd/.Ed  what I did for .Bl/.El

- man 1 uucp doesn't reset the left margin for SEE ALSO (nested .Bl precedes)

- man 1 xmlcatalog and xmllint and xsltproc  loses it in SEE ALSO  -- xsltproc also has weirdness following -o

- man 1 zegrep, zfgrep, zgrep -- nested Bl

- man 1 zipgrep : the description of   pattern   is wrong -- and it eats file[.zip] -- so problem with .IR ?  or .IP?

- man 1 zipinfo : environment option weirdness, and EXAMPLES don't reset to left margin.

- man 1 zshbuiltins : indentation and list handling seems wrong

- man 1 zshcompsys : that first list has a bullet in totally the wrong place.

- man 1 zshcompwid : list bullet placement 

- the zxh functions often have the first element of a list misformatted -- but that may be due to the source 

- man 1 zshmisc -- the indentation seems wonky

- man 1 zshmodules -- the first element of most lists seems wrong. just all the zsh\* man pages have this problem.
