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

- man auditreduce crashes on a Bad Access exception trying to access the source string midway through the line ???
- a man page not found does not display an error

