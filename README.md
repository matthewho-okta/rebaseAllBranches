# rebaseAllBranches
Script to rebase all branches with a certain prefix to the current master

## Usage
- Edit the rebaseAllBranches.sh branch_prefix variable with the prefix you use for your branches
- It's a good idea to delete branches that have already been merged to master
	- See: https://stackoverflow.com/questions/6127328/how-can-i-delete-all-git-branches-which-have-been-merged
	- ```git branch --delete $(git branch --format '%(refname:short)' --merged | grep --invert-match 'main\|master\|branch-to-skip')```
- Another tip is to add this script to your ~/.zshrc as an alias.