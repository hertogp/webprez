#!/bin/bash

# Simple script to run pandoc conversions consistently
# - run it from its own directory

usage() {
    echo "Usage:"
    echo
    echo "  prezto.sh [<framework>] path_to/input.md>"
    echo
    echo "   yields -> path_to/dist/input-framework.html"
    echo
    echo "   <framework> is one of:"
    for f in "${WRITER[@]}"; do
        echo "    - ${f}"
    done
}

# globs

TOP=$(dirname ~/dev/prezto/dummy) # root dir of project (change as needed)
LIB=${TOP}/lib                    # html framework presentations live here
TPL=${TOP}/lib/pandoc             # modified pandoc's templates live here
OUT=dist                          # where all output goes, relative to `pwd`

declare -A WRITER                 # map framework-name -> pandoc writer
WRITER[impress]=html5             # - generic html writer
WRITER[inspire]=html5             # - generic html writer
WRITER[reveal]=revealjs           # - specific html writer
WRITER[slidy]=slidy               # - specific html writer
WRITER[slideous]=slideous         # - specific html writer
WRITER[dzslides]=dzslides         # - specific html writer
WRITER[s5]=s5                     # - specific html writer

EXT=""                            # pandoc extensions to use:
EXT="${EXT}+fenced_divs"          # ::: <class>\n..\n::: => <div class="x">
EXT="${EXT}+pipe_tables"          # easy tables
EXT="${EXT}+escaped_line_breaks"  # for linebreaks in table cells
EXT="${EXT}+lists_without_preceding_blankline"  # doesn't work?
EXT="${EXT}+emoji"

OPT=""                            # pandoc options for conversion
OPT="${OPT} --self-contained"     # offline viewing
OPT="${OPT} --section-divs"       # needed for impress

# MAIN
# - interpret input arguments
if [ $# -eq 1 ]; then
    FMT=reveal  # default to reveal.js as a framework
    SRC=$1;     # relative path to src-file

elif [ $# -eq 2 ]; then
    FMT=$1      # pickup framework requested
    SRC=$2      # relative path to src-file
else
    usage
    exit 1;
fi

if [ ! -s ${SRC} ]; then
    echo "Error: ${SRC} not found or empty!  Nothing to do.."
    exit 1
fi

if [[ -v ${WRITER[${FMT}]} ]]; then
    echo "Error: unknown framework $FMT"
    usage
    exit 1
fi

# RES is pandoc's --resource-path
RES="$(pwd)"                              # current directory
RES="${RES}:$(dirname $(pwd)/${SRC})"     # : src file directory
RES="${RES}:${TOP}"                       # : prezto repo top dir
RES="${RES}:${LIB}"                       # : prezto repo lib dir
RES="${RES}:${LIB}/${FMT}"                # : prezto repo lib/framework dir

DST="$(pwd)/${OUT}/$(dirname ${SRC})"             # target directory
DST="${DST}/$(basename ${SRC/.md/-${FMT}.html})"  # add dst filename

# ensure outp directory is there
if [ ! -d "$(dirname ${DST})" ]; then
    echo "Creating directory $(dirname ${DST})"
    mkdir -p $(dirname ${DST})
fi

echo "Generating $DST"

# Note:
# - Pandoc doesn't use the --resource-path to locate a writer-template
#   file.  Use the --template option to provide a specific path/to/template.

CMD="pandoc --verbose -s"
CMD="${CMD} -f markdown"${EXT}
CMD="${CMD} -t ${WRITER[${FMT}]}"            # map framework to writer
CMD="${CMD} --template=${TPL}/${FMT}.tpl"    # specific path to template
CMD="${CMD} --resource-path=${RES}"          # for finding img, css, js etc..
CMD="${CMD} ${OPT}"                          # add some options
CMD="${CMD} ${SRC} -o ${DST}"                # in & out!

echo "> ${CMD}"
${CMD}

echo "Done!"
