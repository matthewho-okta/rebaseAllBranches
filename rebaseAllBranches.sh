#!/usr/bin/env bash

set -e

#Configurations
branch_prefix="mh"
auto_git_prune_enabled=true
auto_determine_main_or_master=true
auto_delete_resolved_branches=true

if [[ -z $branch_prefix ]] 
then
	printf "ERROR: Edit the branch_prefix in the rebaseAllBranches.sh script. Then retry\n"
	exit 1
fi

deleteResolvedTickets () {
	branches=$(git branch -l "${branch_prefix}*" | sed 's/\*/ /g')
	for branch in $branches
	do
		if [[ "${branch^^}" =~  (OKTA-[0-9]+) ]]
		then
			okta_ticket="${BASH_REMATCH[1]}"
			commits_with_ticket=$(git log -500 --grep="\b${okta_ticket}\b")
			if [[ ! -z $commits_with_ticket ]]
			then
				printf "\tDeleting ${branch}\n"
				git branch -D "${branch}"
			fi
		fi
	done
}

# Start of script

contains_master=false
branches=$(git branch -l | sed 's/\*/ /g')
for branch in $branches
do
	if [ "$branch" == "master" ]
	then
		contains_master=true
	fi
done

target_branch="main"
if [ $contains_master = true ]
then
	target_branch="master"
fi

if [ $auto_delete_resolved_branches = true ]
then
	printf "=================================================================================\n"
	printf "\tDeleting branches where tickets have been resolved\n"
	deleteResolvedTickets
	printf "\tFINISHED: Deleting branches where tickets have been resolved\n"
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
printf "\tUpdating ${target_branch} branch with origin\n"

git checkout ${target_branch}
git fetch origin
git merge --ff-only

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

if [ $auto_git_prune_enabled = true ] 
then
	printf "=================================================================================\n"
	printf "\tAutomatic 'git prune' enabled. \n"
	printf "\tPruning...\n"
	git prune
	printf "\tPruning Complete\n"
	printf "=================================================================================\n"
fi
