#!/bin/bash  -x
set -o errexit

##
# lost - identify missing files
#
#       Create a file system inventory capable of quickly finding
#       the files in one inventory that are missing from another.
#       Also useful for locating files on off-line detachable media.
#       This is the inverse of the 'find duplicates' use case 
#       addressed by fdupes(1).
#       
#       lost -make [ -f ] dir [inventory]
#       lost -from inventory1 inventory2
#       cd root; md5sum -c inventory
#
# HINTS
#       Find duplicates within an inventory.txt (see -dups)
#       awk '{print $1}' "$1"  | grep -v '\*\*\*' | uniq -d | \
#           join -j 1 - <(grep -v '\*\*\*' "$1")
#
#       Needs /bin/bash for <(cut ..) expressions
#
#       Using 'md5 -r' works, but doesn't verify with md5sum, which
#       seems faster anyway.
#
#       The inventory midsuffix is a fake 'volume id' that is the
#       cksum of the 'ls -sS' of the root'
#

usage()
{
    echo ""
    echo "usage: $1"
    echo "   lost -make [ -f ] root [foo.inv] -- make [force] inventory file"
    echo "   lost -from inv1 inv2             -- files in inv2 missing from inv1"
    echo "   lost -dups foo.inv               -- list dups in inventory"
    echo "   lost -s 100g                     -- skip files larger than this"
    echo ""
    echo "   fdupes -r -f root > foo.dups     -- alternative"
    echo "   cat foo.dups | while read f ; do mv "\$f" ~/.Trash/files; done"
    echo ""
    echo "   md5sum -c inventory              -- check, emit failures"
    echo "   md5deep -r -m inventory root     -- check, emit match files"
    echo "   md5deep -r -M inventory root     -- check, emit match hashes"
    echo ""
    echo "   md5deep -r -x inventory root     -- check, emit failed files"
    echo "   md5deep -r -X inventory root     -- check, emit failed hashes"
    echo ""
    echo "   ln -s /usr/bin/hashdeep md5deep"
    echo "   exec -a md5deep hashdeep ..."
    echo ""
    echo "inventory files:"
    ls -l *.inv.txt *.inv 2>/dev/null
    echo ""
    exit 1
}

if [ $# -lt 2 ]; then
    usage "too few arguments:$*" 
fi

if ! type md5deep > /dev/null; then
    echo "needs md5deep"
    exit 1
fi

unset nflag               # like make -n: show
unset mdflags
unset fflag
mdflags="-e"              # md5 chatty default
skflags="-I 100m"         # skip files larger than this
while true; do
    subcmd=$1
    case $subcmd in
    -n)
        shift 1
        nflag=1
        ;;
    -q)
        shift 1
        mdflags=""        # tell md5 be quiet
        ;;
    -v)
        vflag="$1"
        mdflags=""        # tell md5 be quiet so tee can spew
        shift 1
        ;;
    -I|-s)
        skflags="-I $2"
        shift 2
        ;;
    -dups)
        shift 1
        awk '{print $1}' "$1"  | grep -v '\*\*\*' | uniq -d | \
            join -j 1 - <(grep -v '\*\*\*' "$1")
        exit $?
        ;;
    -from)
        shift 1
        comm -2 -3 <(cut -d ' ' -f1 $2 ) <(cut -d ' ' -f1 "$1" ) | \
            join -1 1 -2 1 /dev/stdin $2
        exit $?
        ;;
    -make)
        shift 1
        if [ "$1" = "-f" ]; then
            fflag="$1"
            shift
        fi
        ;;
    *)
        break
        ;;
    esac
done

[ $# -ge 1 ] || usage "invalid arguments: $*"

# Approximate a unique name
rootfold="$1"
fsid=$(ls -sS "$rootfold" | egrep -v '(^total|inv.txt)' | cksum | cut -d ' ' -f 1)

if [ $# -ge 2 ]; then
    invfile="$2"
    invdir="$(dirname $invfile)"
    stem="$(basename "$2" | cut -d. -f 1 | tr -d ' ')"
else
    invdir="."
    stem="$(basename "$1" | cut -d. -f 1 | tr -d ' ')"
fi

invfile="$invdir/$stem.$fsid.inv.txt"

if [ -z "$fflag" -a -f "$invfile" ]; then
    echo "$invfile: already exists, use -f"
    exit 1
fi

if [ -n "$nflag" ]; then
    echo md5deep $mdflags $skflags -o f -l -r "$rootfold" \> "$invfile"

elif [ -n "$vflag" ]; then
    echo md5deep $mdflags $skflags -o f -l -r "$rootfold" \> "$invfile"
    md5deep $mdflags $skflags -o f -l -r "$rootfold" | \
        grep -v '\.inv.txt' | \
        tee /dev/stderr | sort -k1 > "$invfile"
else
    echo md5deep $mdflags $skflags -o f -l -r "$rootfold" \> "$invfile"
    md5deep $mdflags $skflags -o f -l -r "$rootfold" | \
        grep -v '\.inv.txt' | \
        sort -k1 > "$invfile"
fi

