#  TODO

- maybe use "apply" as a screenshot
- clear the last man search, and restore it after it has finished rendering successfully

# BUGS

- man page for awk does not render properly
- man page for c++ does not render properly
- ssh   (-D [bind_address:port] -- loses is because macroblock starts mid-line (twice) for Xo and Oo
- the places where safify needs to be called need to be identified.  Currently, there are places where it needs to be called and isn't.
- in man arch, some of the closing parens are in italic
- in man audiosyncd -- there is a closing .El without an opening .Bl
- man avmediainfo has a .Bl error

- man binhex.pl fails because it misparses: ds C' ""  -- which has a carriage return and continues onto the next line.  This is a standard
   prefix for perl documentaion -- and so I expect it will cause all Perl docs to fail.
   Also, the definition for Vb seems to have worked -- but the substitution does not process the .tm and the .ft as macros.
   
- man captoinfo fails because it uses .TS -- the tbl processor

- man config_data, corelist, cpan, dbicadmin, dbilogstrip, dbiprof, dbiproxy, debinhex.pl ... fail because they are perl docs

- man dig has a problem with  .if  macro.

- man dns-sd misparses  IP  as a macro and renders the line for -P wrong.

- man dyld-usage defines macros INDENT and UNIDENT -- then processes them wrong in the OPTIONS section

- man enc2xs, encguess, eyapp, findrule, h2ph, h2xs, htmltree, instmodsh, ip2cc, jsonpp, json_xs fail to render properly (they are perldoc))

- man expr -- the final paragraph seems to render wrong and reports a .Bl error

- man funzip renders the Example section improperly -- it defines macros  EE  and    EX -- performs the substitution when invoked -- but fails to evaluate the substituted macros.

- man infocmp renders improperly:  The FILES section shows  \*d   and it should be   /usr/share/terminfo

- the SYNOPSIS section should hanging indent the definition of the function if it is too long.  Or treat is a two column table with the name in the first column and the definition in the second (like a .Bl).  Noticed on man install

- LEGACY mode fails on man jq -- it terminates reading the stdout too soon -- borrow the code from ShellTesting .  Noticed because the BUGS section has an extra final dot in the render.

- man ksh doen't handle the roff prelude definitions properly -- looks like a mess.

- man ktrace has many .Bl errors.  Also,  .It Nm Cm info  does not display the Nm.  It defines (.de) trace-opts, then doesn't evaluate it properly.

- man leave -- there is an extra space following the + option.

- man less fails because the file is less.1.gz -- need to be able to handle compressed man files.  Also true for lessecho and lesskey and more

- man libnetcfg, lsm, lwp-download, lwp-dump, lwp-mirror, lwp-request, macerror, net-server fail to render properly (they are perldoc))

- man mailq (and sendmail) is a mess.

- man mdimport has Bl errors for  .Bd -literal

- man netusage-client (and netusage)  -- .It Xo Cm --all-traffic  doesn't render in NETWORK STATISTICS COMMANDS

- man nslookup    ARGUMENTS render incorrectly

- man ocspd    the first file in FILES  does not render properly

- man package-stack-conflicts, par.pl, parl, perl fail to render properly (they are perldoc))

- man patch  fails to render  .Qo and .Qc

- all the perl\* (and there are many) fail to render properly (they are perldoc))

- man piconv, pl2pm fail to render properly (they are perldoc))

- man plockstat renders improperly

- man pmset loses it on the last SYNOPSIS line.

- all the pod\* ( and there are many) fail to render properly (they are perldoc)

- man postcat fails to notice the DESCRIPTION section 

- man postconf fails to parse  .ti   macros

- man postmap crashes in nextline() -- in the removeFirst() -- clearly a race condition 
            if !lines.isEmpty { lines.removeFirst() }
 
- man 5 postconf -- weird indents in SEE ALSO and AUTHORS

- man 1 postconf -- the phrase        postconf html_directory    is half bold half not because the sequence \fB and \fR are split across lines.
     The parse should remember its font state from the previous line and proceed from there.

- more perldoc mans:  pp, prove, ptar

