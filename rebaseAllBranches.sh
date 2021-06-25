#!/bin/bash

#Configurations
branch_prefix=""
git_prune_enabled=false
use_master_instead_of_main=true

if [[ -z $branch_prefix ]] 
then
	printf "ERROR: Edit the branch_prefix in the rebaseAllBranches.sh script. Then retry\n"
	exit 1
fi

# Start of script
target_branch="main"
if [ $use_master_instead_of_main = true ] 
then
	target_branch="master"
fi

prev_branch=$(git branch --show-current)
printf "=================================================================================\n"
printf "\tRebasing all branches with the following prefix ${branch_prefix} onto branch ${target_branch}\n"
printf "=================================================================================\n"
conflicts=$(git ls-files -u)
if [[ ! -z $conflicts  ]] 
then
	printf "There are existing conflicting files on this branch. Pleas fix this and then retry: Branch=${branch} Files=${conflicts}\n"
	exit 1
fi


stashed=false
if [[ $(git status -s) ]] 
then
	printf "\n\tUncommitted changes found. Stashing changes\n"
	git stash -u
	stashed=true
else
	printf "\n\tNo uncommitted changes found. No stash will be created\n"
fi

printf "=================================================================================\n"

git checkout ${target_branch}
git pull origin ${target_branch}

branches=$(git branch -l "${branch_prefix}*" | sed 's/\*/ /g')
for branch in $branches 
do
	printf "=================================================================================\n"
	printf "\tRebasing ${branch}\n"
	git checkout $branch && git rebase ${target_branch}
	conflicts=$(git ls-files -u)
	if [[ ! -z $conflicts  ]] 
	then
		printf "CONFLICTING FILES: Branch=${branch} Files=${conflicts}\n"
		exit 1
	fi

	printf "\tFINISHED: Rebasing ${branch}\n"
done

printf "=================================================================================\n"
printf "\tSwitching back to ${prev_branch}\n"
git checkout $prev_branch
printf "=================================================================================\n"

if [ $stashed = true ] 
then
	printf "Found a previous stash. Popping stash off the stack.\n"
	git stash pop
else
	printf "No previous stash found.\n"
fi

if [ $git_prune_enabled = true ] 
then
	printf "=================================================================================\n"
	printf "\tAutomatic `git prune`\n"
	git prune
fi
