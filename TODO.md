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
