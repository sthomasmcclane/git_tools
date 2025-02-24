#!/bin/bash

YELLOW='\033[0;93m' # ANSI escape code for a brighter yellow color
RESET='\033[0m'    # ANSI escape code to reset the color

printf "${YELLOW}Source branch? (Enter for current)${RESET}\n"
read SOURCE
if [ -z "$SOURCE" ]; then
    SOURCE=$(git rev-parse --abbrev-ref HEAD)
fi

printf "Source branch is ${YELLOW}$SOURCE${RESET}\n"

printf "${YELLOW}Destination branch?${RESET}\n"
read DEST

printf "Destination branch is ${YELLOW}$DEST${RESET}\n"

printf "${YELLOW}Commit message?${RESET}\n"
read MESS

printf "${YELLOW}Checking out and updating the source branch: $SOURCE${RESET}\n"
sleep 2
git checkout $SOURCE
git pull

printf "${YELLOW}Checking out and updating the destination branch: $DEST${RESET}\n"
sleep 2
git checkout $DEST
git pull

printf "${YELLOW}Merging...${RESET}\n"
sleep 2
git merge --squash $SOURCE

printf "${YELLOW}Continue? (y|n)${RESET}\n"
read ANS

case $ANS in
    n) echo "Fix conflicts, save, commit, and push to continue."
        exit ;;
    y) echo "Committing and pushing"
        if [ $SOURCE = 'master' ]; then
            sleep 2
            git commit -am "$MESS"
            git push
        else
            sleep 2
            git commit -am "$SOURCE: $MESS"
            git push
        fi
        ;;
esac

if [ "$SOURCE" = 'master' ] || [ "$SOURCE" = 'main' ]; then
    exit
else
    printf "${YELLOW}Is the source branch still required?${RESET}\n"
    read DEL
    case $DEL in
        y) exit ;;

        n) printf "Deleting ${YELLOW}$SOURCE${RESET} remote...\n"
        sleep 1
        git push origin --delete "$SOURCE"
        printf "Deleting ${YELLOW}$SOURCE${RESET} tracking...\n"
        sleep 1
        git fetch origin --prune
        printf "Deleting ${YELLOW}$SOURCE${RESET} local...\n"
        sleep 1
        git branch -D "$SOURCE"

        exit
        ;;
    esac
fi
