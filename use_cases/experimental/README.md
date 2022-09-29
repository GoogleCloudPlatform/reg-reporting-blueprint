
# Instructions for merging Github on to Git on Borg

Note: [Git on Borg Repository](https://cloud-fsi-solutions-review.git.corp.google.com/admin/repos/reg-reporting-blueprint,general>).

Check the current remotes.
```
git remote -v
```

The output should be similar to this:
```
origin  sso://cloud-fsi-solutions/reg-reporting-blueprint (fetch)
origin  sso://cloud-fsi-solutions/reg-reporting-blueprint (push)
```

## Add Github as a remote
```
git add remote github git@github.com:GoogleCloudPlatform/reg-reporting-blueprint.git      
```

## Check differences from github

NOTE: Stash or commit any changes to a branch, and switch to main. Ensure there
are no staged files.

Fetch all changes from github main branch. This does not merge anything!
```
git fetch github main
```

Find differences from github main for files only:
```
git diff github/main --name-only
```

Find all differences from github main:
```
git diff github/main
```

## Create an update for gerrit

Create a branch on main:
```
git switch -c github_sync
```

Fetch the current files (as-is, copied) from github main to the current working
set:
```
git restore --overlay --source github/main .
```

Note that this will then require some fix-up if there are any conflicts.
Conflicts will *not* be highlighted, rather, the new content will simply be
committed on top of the old.

Use `git diff` to check for changes (the same output as git diff github/main
previously), and resolve any changes that are needed.

These should be minimised by using different directories.

Commit the changes when done:
```
git commit -m "Synchronizing with github reg-reporting-blueprint"
```

Check the log to ensure the second last commit is branched is origin/main:
```
git log -2
```

Create gerrit change request:
```
git push origin HEAD:refs/for/main
```

