# Repair mangled escapes in listings

s/b'<:'/<:/g
s/b':>'/:>/g


# dblatex generates lstlisting with multiple parameter-blocks, and that doesn't work.
# Remove the escapeinside={<:}{:>} block and then replace those sequences with <t>...</t>
# This is likely to be fragile.

s|\\begin{lstlisting}\[escapeinside={<:}{:>}]\[firstnumber=1,escapeinside={<t>}{</t>}|\\begin{lstlisting}[firstnumber=1,escapeinside={<t>}{</t>},|
s|<:|<t>|g
s|:>|</t>|g
