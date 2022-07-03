#!/bin/bash

##############################################################################
# Name: create-mirror-keys.sh
#
# Description: Creates SSH keys to be used by the git-mirror action.
#
# Options:
#   -h
#      Output the usage statement.
#   -k NAME
#      The name for the deploy keys.
#   -r REPO
#      Comma separated list of repositories for which keys should be
#      generated.
#   -t TOKEN
#      The GitHub token to use to authenticate with the GitHub REST API.
#   -u
#      Upload the generated public key to the respective repository.
#   -w DIR
#      The directory into which generated keys should be written. Defaults to
#      a temporary directory.
##############################################################################
set -eu -o pipefail

rootdir=$(cd -P "$(dirname "$0")" > /dev/null && pwd)

usage () {
	code=$0

	if [[ "${code}" -eq "0" ]]; then
		exec 2>&1
	fi
	printf "Usage: %s\n" $(basename $0) >&2
	exit "${code}"
}

upload=0
dest="$(mktemp -d)"
while getopts ":hk:r:t:uw:" option; do
  case "$option" in
		  h)
				usage 0
				;;
			k)
				key="${OPTARG}"
				;;
			r)
				repos="${OPTARG}"
				;;
			t)
				token="${OPTARG}"
				;;
			u)
				upload=1
				;;
			w)
				dest="${OPTARG}"
				;;
			*)
				printf "unrecognized option: %s\n" "${OPTARG}" >&2
	      usage 1
				;;
  esac
done
shift $((OPTIND - 1))

if [[ "${upload}" -ne "0" ]]; then
	if ! curl --silent --fail -H "Authorization: token ${token}" -H "Accept: application/vnd.github+json" "https://api.github.com/user" >/dev/null; then
		printf "could not authenticate with GitHub. Set token to upload deploy keys\n" >&2
		usage 1
	fi
fi

repos="$(printf "%s" "${repos}" | tr 's' ',' | tr ',' ' ')"
for repo in $repos
do
	org="$(dirname "${repo}")"
	mkdir -p "${dest}/${org}"
	printf "creating key for %s\n" "${repo}" >&2
	ssh-keygen -N "" -t ed25519 -C "sf-to-gh-${repo}" -f "${dest}/${repo}"

	if [[ "${upload}" != "1" ]]; then
		continue
	fi

	keys=$(curl --silent --fail -H "Authorization: token ${token}" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${repo}/keys" | jq .[].id)

	if [[ -n "${keys}" ]]; then
		printf "keys named mirror_sync in %s:\n%s\n" "${repo}" "${keys}">&2
		numkeys="$(printf "%s\n" "${keys}" | wc -l | tr -d " ")"
		read -p "mirror_sync deploy key (${numkeys} instances) in ${repo} already exists. Do you want to delete it? (y/n)"
		if [[ "${REPLY}" != "y" ]]; then
			printf "leaving mirror_sync deploy key(s) in ${repo} in place.\n" >&2
			continue
		fi

		printf "deleting mirror_sync deploy key(s) in ${repo}\n" >&2
		for key in ${keys}; do
			curl --fail -H "Authorization: token ${token}" -H "Accept: application/vnd.github+json" -X DELETE "https://api.github.com/repos/${repo}/keys/${key}"
		done
	fi

	printf "creating mirror_sync deploy key in ${repo}\n" >&2
	json='{"title": "mirror_sync", "key": "'$(cat ${dest}/${repo}.pub)'", "read_only": false}'
	curl --silent --fail -H "Authorization: token ${token}" -H "Accept: application/vnd.github+json" -H "Content-Type: application/json" -d @- "https://api.github.com/repos/${repo}/keys" <<<"$json" >/dev/null
done
