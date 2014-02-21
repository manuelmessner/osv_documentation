#!/usr/bin/env sh

for graphic in $*
do
    dest=$(echo $graphic | sed 's/\.[0-9]*/\.graphic\.tex/')

    echo -e "\t[GEN]\t$(basename $graphic) -> $(basename $dest)"

    cat <<EOF > $dest
        \documentclass{article}

        % The following is needed in order to make the code compatible
        % with both latex/dvips and pdflatex.
        \ifx\pdftexversion\undefined
        \usepackage[dvips]{graphicx}
        \else
        \usepackage[pdftex]{graphicx}
        \DeclareGraphicsRule{*}{mps}{*}{}
        \fi

        \title{A Minimal Example}
        \author{Generator script}

        \begin{document}
            \maketitle
            \section{Example}
            \includegraphics[width=1\textwidth]{$graphic}
        \end{document}
EOF

    echo -e "\t[LATEX]\t$dest"
    $LATEX $LATEX_FLAGS $dest >> $MAKELOG

done

