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
- a man page not found does not display an error

- man binhex.pl fails because it misparses: ds C' ""  -- which has a carriage return and continues onto the next line.  This is a standard
   prefix for perl documentaion -- and so I expect it will cause all Perl docs to fail.
   Also, the definition for Vb seems to have worked -- but the substitution does not process the .tm and the .ft as macros.
   
- man bitesize.d  fails to render at all -- I believe because the file is bitesize.d.1m  -- and that final m causes confusion.

- man 1 bluetoothuserd   fails to render at all, because the filename is  bluetoothuserd.8  .  The error in legacy mode is: no manual entry for bluetoothused
  but it also does no manual entry for /  -- only the first line should be the error.   However, the command line man also fails to find it -- so a
  "not found" error is ok.  However, non-legacy does not display an error message
  
- man captoinfo fails because the file is  captoinfo.1m   It does not provide an error message

- man config_data, corelist, cpan ... fail because they are perl docs
