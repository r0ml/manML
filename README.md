
# manML

This app is meant to display man pages written using mandoc.  Rather than use the existing mandoc/roff commands,
this app re-implements the parsing and formatting in native Swift.  (There is an option to use the system
generated output).

The text field takes either of the form:

1) the man command or function to display (e.g. man)
2) the section followed by the command or function name, separated by a space (e.g. 2 open)

Additionally, one can drag and drop a mandoc file onto the input field,
and it will be parsed and displayed assuming that it is mandoc text.

If one clicks anywhere on the output (in manML mode) it will display the mandoc source code which generated
that piece of output as the footer.  The up and down buttons on the right of the footer line will scroll
within the mandoc source code -- showing the previous or following line(s).

I built this to understand mandoc (and roff) better in case I wanted to author or edit man pages.
Also, to have more elegantly formatted man pages.

- 2 stat -- has embedded .TS -- which uses formatting for the `tbl` command.  Which is not yet implemented

