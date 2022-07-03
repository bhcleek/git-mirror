# Git Mirror

A GitHub Action for mirroring repositories.

## Usage

### GitHub Actions
```
# File: .github/workflows/mirror.yml

on:
  schedule:
  - cron:  "15 * * * *"
  workflow_dispatch:

jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        persist-credentials: false
    - name: mirror
      uses: bhcleek/github-mirror@v1
      with:
        source_repo: "source/repository"
        destination_repo: "destination/repository"
        github_token: "${{ secrets.GITHUB_TOKEN }}" # optional
        ssh_private_key: "${{ secrets.SSH_PRIVATE_KEY }}" # optional
        source_ssh_private_key: "${{ secrets.SOURCE_SSH_PRIVATE_KEY }}" # optional, will override `SSH_PRIVATE_KEY`
        destination_ssh_private_key: "${{ secrets.DESTINATION_SSH_PRIVATE_KEY }}" # optional, will override `SSH_PRIVATE_KEY`
```

If `source_repo` is private or with another provider, either (1) use an authenticated HTTPS repo clone url like `https://${access_token}@github.com/owner/repository.git` or (2) set a `SSH_PRIVATE_KEY` secret environment variable and use the SSH clone url

If `destination_repo` is private or with another provider, either (1) use an authenticated HTTPS repo clone url like `https://${access_token}@github.com/owner/repository.git` or (2) set a `SSH_PRIVATE_KEY` secret environment variable and use the SSH clone url

Either `destination_repo` or `source_repo` can be omitted or left empty. The current repository will be used for the respective value in that case.

The workflow will need to be defined in the upstream repository in order to continue mirroring if `destination_repo` is not defined or refers to the current repository.

##### Using shorthand

You can use GitHub repo shorthand like `username/repository`.

When using a GitHub repos with shorthand, the `github_token` must be set. Note that GitHub Actions automatically inject a secret with write access to the current repository.

##### Using ssh

> The `ssh_private_key`, or `source_ssh_private_key` and `destination_ssh_private_key` must be supplied if using ssh clone urls.

```yml
source_repo: "git@github.com:username/repository.git"
```
