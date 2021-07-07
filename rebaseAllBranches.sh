#!/bin/bash
set -e

#Configurations
branch_prefix="mh"
git_prune_enabled=true
use_master_instead_of_main=false
auto_determine_main_or_master=true

if [[ -z $branch_prefix ]] 
then
	printf "ERROR: Edit the branch_prefix in the rebaseAllBranches.sh script. Then retry\n"
	exit 1
fi

# Start of script

contains_master=false
if [ $auto_determine_main_or_master = true ]
then
	branches=$(git branch -l | sed 's/\*/ /g')
	for branch in $branches
	do
		if [ "$branch" == "master" ]
		then
			contains_master=true
		fi
	done
fi

target_branch="main"
if [ $use_master_instead_of_main = true ] || [ $contains_master = true ]
then
	target_branch="master"
fi

prev_branch=$(git branch --show-current)
cur_date=$(date)
printf "=================================================================================\n"
printf "\tRebasing all branches with the following prefix ${branch_prefix} onto branch ${target_branch}\n"
printf "\t\t${cur_date}\n"
printf "=================================================================================\n"
conflicts=$(git ls-files -u)
if [[ ! -z $conflicts  ]] 
then
	printf "There are existing conflicting files on this branch. Please fix this and then retry: Branch=${prev_branch} Files=${conflicts}\n"
	exit 1
fi


stashed=false
if [[ $(git status -s) ]] 
then
	stash_name="${prev_branch}: ${cur_date}"
	printf "\tUncommitted changes found. Stashing changes with message '${stash_name}'\n"
	git stash push --include-untracked -m ""
	stashed=true
else
	printf "\tNo uncommitted changes found. No stash will be created\n"
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
	printf "\tAutomatic 'git prune' enabled. \n"
	printf "\tPruning...\n"
	git prune
	printf "\tPruning Complete\n"
	printf "=================================================================================\n"
fi
