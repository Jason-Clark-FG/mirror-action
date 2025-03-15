#!/usr/bin/env bash
set -e

if [[ "${DEBUG}" -eq "true" ]]; then
    set -x
fi

git config --global --add safe.directory /github/workspace

GIT_USERNAME=${INPUT_GIT_USERNAME:-${GIT_USERNAME:-"git"}}
REMOTE=${INPUT_REMOTE:-"$*"}
REMOTE_NAME=${INPUT_REMOTE_NAME:-"mirror"}
GIT_SSH_PRIVATE_KEY=${INPUT_GIT_SSH_PRIVATE_KEY}
GIT_SSH_PUBLIC_KEY=${INPUT_GIT_SSH_PUBLIC_KEY}
GIT_REF=${INPUT_GIT_REF}
GIT_PUSH_ARGS=${INPUT_GIT_PUSH_ARGS:-"--force --prune"}
GIT_SSH_NO_VERIFY_HOST=${INPUT_GIT_SSH_NO_VERIFY_HOST}
GIT_SSH_KNOWN_HOSTS=${INPUT_GIT_SSH_KNOWN_HOSTS}
HAS_CHECKED_OUT="$(git rev-parse --is-inside-work-tree 2>/dev/null || /bin/true)"
BRANCH_BATCH_SIZE=${INPUT_BRANCH_BATCH_SIZE:-50}
PUSH_TAGS=${INPUT_PUSH_TAGS:-true}
BATCH_SLEEP_INTERVAL=${INPUT_BATCH_SLEEP_INTERVAL:-5}
FAILED_BRANCHES=()

if [[ "${HAS_CHECKED_OUT}" != "true" ]]; then
    echo "WARNING: repo not checked out; attempting checkout" > /dev/stderr
    echo "WARNING: this may result in missing commits in the remote mirror" > /dev/stderr
    echo "WARNING: this behavior is deprecated and will be removed in a future release" > /dev/stderr
    echo "WARNING: to remove this warning add the following to your yml job steps:" > /dev/stderr
    echo " - uses: actions/checkout@v3" > /dev/stderr
    if [[ "${SRC_REPO}" -eq "" ]]; then
        echo "WARNING: SRC_REPO env variable not defined" > /dev/stderr
        SRC_REPO="https://github.com/${GITHUB_REPOSITORY}.git" > /dev/stderr
        echo "Assuming source repo is ${SRC_REPO}" > /dev/stderr
    fi
    git init > /dev/null
    git remote add origin "${SRC_REPO}"
    git fetch --all > /dev/null 2>&1
fi

git config --global credential.username "${GIT_USERNAME}"

if [[ "${GIT_SSH_PRIVATE_KEY}" != "" ]]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "${GIT_SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
    if [[ "${GIT_SSH_PUBLIC_KEY}" != "" ]]; then
        echo "${GIT_SSH_PUBLIC_KEY}" > ~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa.pub
    fi
    chmod 600 ~/.ssh/id_rsa
    if [[ "${GIT_SSH_KNOWN_HOSTS}" != "" ]]; then
        echo "${GIT_SSH_KNOWN_HOSTS}" > ~/.ssh/known_hosts
        git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=~/.ssh/known_hosts"
    else
        if [[ "${GIT_SSH_NO_VERIFY_HOST}" != "true" ]]; then
            echo "WARNING: no known_hosts set and host verification is enabled (the default)"
            echo "WARNING: this job will fail due to host verification issues"
            echo "Please either provide the GIT_SSH_KNOWN_HOSTS or GIT_SSH_NO_VERIFY_HOST inputs"
            exit 1
        else
            git config --global core.sshCommand "ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
        fi
    fi
else
    git config --global core.askPass /cred-helper.sh
    git config --global credential.helper cache
fi

git remote add ${REMOTE_NAME} "${REMOTE}"

if [[ "${INPUT_PUSH_ALL_REFS}" != "false" ]]; then
    # Batch pushing logic
    remote_branches=($(git branch -r | awk '/origin\//{gsub(/origin\//,"");print $1}'))

    for i in $(seq 0 $((${#remote_branches[@]} - 1))); do
        branch=${remote_branches[$i]}
        if (( $i % $BRANCH_BATCH_SIZE == 0 )); then
            batch=()
        fi
        batch+=("refs/remotes/origin/$branch:refs/heads/$branch")
        if (( $i % $BRANCH_BATCH_SIZE == $(($BRANCH_BATCH_SIZE - 1)) || $i == $((${#remote_branches[@]} - 1)) )); then
            if ! eval git push ${GIT_PUSH_ARGS} ${REMOTE_NAME} "${batch[@]}"; then
                # Capture failed branch names
                for failed_ref in "${batch[@]}"; do
                    failed_branch=$(echo "$failed_ref" | awk -F':' '{print $2}')
                    FAILED_BRANCHES+=("$failed_branch")
                done
            fi
            sleep $BATCH_SLEEP_INTERVAL
        fi
    done
    # Retry failed branches
    if [[ ${#FAILED_BRANCHES[@]} -gt 0 ]]; then
        echo "Retrying failed branches: ${FAILED_BRANCHES[@]}"
        for failed_branch in "${FAILED_BRANCHES[@]}"; do
            if ! eval git push ${GIT_PUSH_ARGS} ${REMOTE_NAME} "refs/remotes/origin/$(echo $failed_branch | sed 's/refs\/heads\///'):$failed_branch"; then
                echo "Failed to retry branch: $failed_branch"
            fi
        done
    fi
    # Push tags separately after branches, if configured.
    if [[ "${PUSH_TAGS}" == "true" ]]; then
        eval git push ${GIT_PUSH_ARGS} ${REMOTE_NAME} --tags
    fi
else
    if [[ "${HAS_CHECKED_OUT}" != "true" ]]; then
        echo "FATAL: You must upgrade to using actions inputs instead of args: to push a single branch" > /dev/stderr
        exit 1
    else
        eval git push -u ${GIT_PUSH_ARGS} ${REMOTE_NAME} "${GIT_REF}"
    fi
fi
