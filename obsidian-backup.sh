#!/usr/bin/env bash

# this script will back up your Obsidian vault (or any folder really)
# - backups use zstd for high compression, and archives are timestamped 
# - backups will be automatically pruned after 7 days
# - duplicates will be avoided by comparing the hashes of the archives
# - you can pass `-f <filename>` to search your backups (partial names accepted)
# - a file called "dirsize_XXX" will be saved alongside the backups so you can quickly check the size of your entire backup dir

# set SRC to the root of your Obsidian vaults (or a specific vault)
SRC="$HOME/Obsidian"

# set DST to the path where you want your backups saved
DST="$HOME/Obsidian-Backups"

############## DO NOT EDIT ANYTHING BELOW THIS LINE ##############

if ! hash gtar zstd 2>/dev/null; then
  echo "this script requires gtar and zstd -- try \`brew install gnu-tar zstd\`"
  exit 1
fi

_find() {
  [ -n "$1" ] || { echo "specify a filename (or partial filename), e.g. \`foo\`"; return; }
  cd "$DST" || return
  while read -r fname; do
    gtar --ignore-case --wildcards --list --file "$fname" "*/${1}*" 2>/dev/null |
    awk -v f="${fname##*/}:" '{ printf "%-47s %s\n", f, $0 }'
  done < <(find -s . -name "obsidian-backup-*" -type f)
}

USAGESTR="${0##*/} [-f <pattern>]"
SRC_NAME="${SRC##*/}"
BACKUP_FILENAME="obsidian-backup-$(date +%Y-%m-%d).$EPOCHSECONDS.tar.zst"
tmptar='/tmp/obsidian_backup.tar.zst'
hashfile="$DST/previous_hash"
export COPYFILE_DISABLE=true

case $1 in
  -h|--help) echo "$USAGESTR"; exit;;
  -f|--find) _find "$2"; exit;;
esac

[[ -d $SRC ]] || { echo "$SRC does not exist"; exit 1; }
[[ -d $DST ]] || mkdir -p "$DST"
echo "backing up ${SRC_NAME} to ${BACKUP_FILENAME}"
cd -- "$SRC" || exit 1
cd .. || exit 1

if gtar --use-compress-program='zstd -T12 -15' --create --file "$tmptar" --exclude '.DS_Store' -- "$SRC_NAME/" 2>/dev/null; then
  read -r backup_hash _ < <(shasum -a 256 "$tmptar")
  [ -e "$hashfile" ] && read -r previous_hash _ <"$hashfile"
  if [ "$backup_hash" == "$previous_hash" ]; then
    echo "hashes match, skipping backup"
    rm "$tmptar"
  else
    echo "saving new hash: $backup_hash"
    echo "$backup_hash" >"$hashfile"
    mv "$tmptar" "${DST}/${BACKUP_FILENAME}"
    echo "pruning old backups"
    find -E "${DST:?}" -regex ".*(gz|xz|rar|zst)$" -mtime +7d -delete
    read -r dirsize _ < <(du -hs "$DST")
    find "${DST:?}" -type f -name "dirsize_*" -delete
    touch "${DST:?}/dirsize_${dirsize:?}"
    echo "new dirsize=${dirsize:?}"
  fi
  exit 0
else
  echo "error creating archive"
  exit 1
fi
