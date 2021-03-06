#!/bin/sh

set -e -o pipefail

sshtmp="${RUNNER_TEMP}/ssh"
mkdir -p "${sshtmp}"

if [[ -n "${SSH_PRIVATE_KEY}" ]]; then
  printf "Saving SSH_PRIVATE_KEY\n" >&2

  printf "%s\n" "${SSH_PRIVATE_KEY}" | sed 's/\\n/\n/g' > "${sshtmp}/src_rsa"
  printf "%s\n" "${SSH_PRIVATE_KEY}" | sed 's/\\n/\n/g' > "${sshtmp}/dst_rsa"
  chmod 600 "${sshtmp}/src_rsa"
  chmod 600 "${sshtmp}/dst_rsa"
fi

if [[ -n "${UPSTREAM_SSH_PRIVATE_KEY}" ]]; then
  printf "Saving UPSTREAM_SSH_PRIVATE_KEY\n" >&2
  printf "%s\n" "${UPSTREAM_SSH_PRIVATE_KEY}" | sed 's/\\n/\n/g' > "${sshtmp}/src_rsa"
  chmod 600 "${sshtmp}/src_rsa"
fi

if [[ -n "${DESTINATION_SSH_PRIVATE_KEY}" ]]; then
  printf "Saving DESTINATION_SSH_PRIVATE_KEY\n" >&2
  printf "%s\n" "${DESTINATION_SSH_PRIVATE_KEY}" | sed 's/\\n/\n/g' > "${sshtmp}/dst_rsa"
  chmod 600 "${sshtmp}/dst_rsa"
fi

set -u

# Github action changes $HOME to /github at runtime
# therefore we always copy the SSH key to $HOME (aka. ~)
if ! ls "${HOME}"/.ssh > /dev/null 2>&1; then
  mkdir --parents "${HOME}"/.ssh
fi

mv "${sshtmp}"/* "${HOME}"/.ssh || true

rmdir "${sshtmp}"

DEST_REPO=$1
UPSTREAM_REPO=$2
/git-mirror.sh "${DEST_REPO}" "${UPSTREAM_REPO}"
