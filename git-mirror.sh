#!/bin/bash

set -e -o pipefail

DEST_REPO=$1
UPSTREAM_REPO=$2

if [[ -z "${DEST_REPO}" && -z "${UPSTREAM_REPO}" ]]; then
  printf "Both destination and source are empty; nothing to be done.\n" >&2
  exit 0
fi

if [[ -z "${DEST_REPO}" ]]; then
  DEST_REPO="${GITHUB_REPOSITORY}"
fi

if [[ -z "${UPSTREAM_REPO}" ]]; then
  UPSTREAM_REPO="${GITHUB_REPOSITORY}"
fi

if [[ "${DEST_REPO}" == "${UPSTREAM_REPO}" ]]; then
  printf "Destination and source are the same; nothing to be done.\n" >&2
  exit 0
fi

if ! printf ${UPSTREAM_REPO} | grep -Eq ':|@|\.git\/?$'; then
  printf "UPSTREAM_REPO does not seem to be a valid git URI, assuming it's a GitHub repo\n" >&2
  printf "Originally: %s\n" "${UPSTREAM_REPO}" >&2

  if [[ -f "${HOME}/.ssh/src_rsa" ]]; then
    UPSTREAM_REPO="git@github.com:${UPSTREAM_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  else
    UPSTREAM_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${UPSTREAM_REPO}.git"
  fi

  printf "Now: %s \n" "${UPSTREAM_REPO}" >&2
fi

if ! printf ${DEST_REPO} | grep -Eq ':|@|\.git\/?$'; then
  printf "DEST_REPO does not seem to be a valid git URI, assuming it's a GitHub repo\n" >&2
  printf "Originally: %s\n" "${DEST_REPO}" >&2

  if [[ -f "${HOME}/.ssh/dst_rsa" ]]; then
    DEST_REPO="git@github.com:${DEST_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  else
    DEST_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${DEST_REPO}.git"
  fi

  printf "Now: %s \n" "${DEST_REPO}" >&2
fi

set -u

mirrordir="${RUNNER_TEMP}/$(basename "${GITHUB_REPOSITORY}")"
mkdir -p "$mirrordir"
cd "$mirrordir"

git init --bare --quiet

printf "Adding upstream %s\n" "${UPSTREAM_REPO}" >&2
git remote add upstream --mirror=fetch "${UPSTREAM_REPO}"
printf "Adding upstream %s\n" "${DEST_REPO}" >&2
git remote add origin --mirror=push "${DEST_REPO}"
git remote --verbose

printf "Getting upstream\n" >&2
git -c core.sshCommand="/usr/bin/ssh -i ~/.ssh/src_rsa" fetch --quiet upstream

# refs/pull is a special namespace for GitHub. Special case it for now until
# there's a need for more robust handling. Remove any refs/pull/* refs and
# fetch the refs/pull/* from the destination before mirroring to the
# destination.
git -c core.sshCommand="/usr/bin/ssh -i ~/.ssh/dst_rsa" fetch --quiet --prune origin '+refs/pull/*:refs/pull/*'

printf "Pushing changes from upstream to origin\n" >&2
git -c core.sshCommand="/usr/bin/ssh -i ~/.ssh/dst_rsa" push origin
