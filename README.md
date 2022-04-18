# obsidian-backup

_see related thread at https://forum.obsidian.md/t/backup-obsidian-for-beginners/12267/33_

## Summary

This script will back up your Obsidian vault (or any folder really)
 - backups use zstd for high compression
 - archives are timestamped 
 - backups are automatically pruned after 7 days
 - duplicates will be avoided by comparing the hashes of the archives
 - you can pass `-f <filename>` to search your backups (partial names accepted)
 - a file called `dirsize_XXX` will be saved alongside the backups so you can quickly check the size of your entire backup dir

## How to Use

1. download `obsidian-backup.sh`
2. edit the file and set `SRC` to the root of your Obsidian vaults (or a specific vault). If this path does not exist, the script will abort.
3. set `DST` to the path where you want your backups saved. (if the destination path does not exist, the script will try to create it)
4. copy the file somewhere in your `$PATH` (`/usr/local/bin` is usually a good choice)
5. make sure it's executable (`chmod +x obsidian-backup.sh`)

From then on, you can just run it at the Terminal, or use whatever method you want for scheduling it. I use the native macOS launchd—there's an example LaunchAgent (`obsidian-backup.plist`) that runs backups every hour in this git repo if you want to import and use that. To import it, you can run the commands below:

```shell
cp obsidian-backup.plist ~/Library/LaunchAgents
chmod 644 ~/Library/LaunchAgents/obsidian-backup.plist
launchctl load ~/Library/LaunchAgents/obsidian-backup.plist
```

> _You may need to edit the plist to correct the paths if they are different on your system. The "shebang" on the first line should include the path to your `$HOMEBREW_PREFIX/bin` directory._
