# rebaseAllBranches
Script to rebase all branches with a certain prefix to the current origin master / main. The script will stash any uncommitted changes (Including untracked changes)  and swap back to the same branch if there are no conflicts during rebasing.

If there are conflicts during the rebase, you need to fix the conflict and manually pop the stash on your original branch.

## Usage
- Edit the rebaseAllBranches.sh branch_prefix variable with the prefix you use for your branches
- There's the option to delete branches that have already been merged to master
