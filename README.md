# mirror-action-ng

A GitHub Action for mirroring your commits to a different remote repository

This project itself is based on [yesolutions/mirror-action](https://github.com/yesolutions/mirror-action) which also is [mirrored on GitLab](https://gitlab.com/yesolutions/mirror-action)

The main change is to introduce batching of pushes to branches since GitHub appears to be limiting this, which is creating issues mirroring repositories with a large number of branches. In addition, failed branches will be tracked and then retried individually after the initial branch batches.

This required some more variables to be added:

|  Variable Name         | Default |
|------------------------|---------|
| `BRANCH_BATCH_SIZE`    | `50`    |
| `PUSH_TAGS`            | `true`  |
| `BATCH_SLEEP_INTERVAL` | `5`     |

Additionally pushing tags was split to a second action after the push of the branches, it will execute by default unless the `PUSH_TAGS` variable is set to `false`.

## Example workflows

### Mirror a repository with username/password over HTTPS

For example, this project uses the following workflow to mirror from GitHub to GitLab

```yaml
on: [push]
  ...
      steps:
        - uses: actions/checkout@v4
          with:
            fetch-depth: 0
        - uses: Jason-Clark-FG/mirror-action-ng@main
          with:
            REMOTE: 'https://gitlab.com/spyoungtech/mirror-action-ng.git'
            GIT_USERNAME: spyoungtech
            GIT_PASSWORD: ${{ secrets.GIT_PASSWORD }}
```

Be sure to set the `GIT_PASSWORD` secret in your repo secrets settings.

**NOTE:** by default, all branches are pushed. If you want to avoid
this behavior, set `PUSH_ALL_REFS: "false"`

You can further customize the push behavior with the `GIT_PUSH_ARGS` parameter.
By default, this is set to `--force --prune`.

Tags if selected will be pushed after the branch pushes with the default flags plus `--tags`

If something goes wrong, you can debug by setting `DEBUG: "true"`

### Mirror a repository using SSH

Requires version 0.4.0+

Pretty much the same, but using `GIT_SSH_PRIVATE_KEY` and `GIT_SSH_KNOWN_HOSTS`

```yaml
      steps:
        - uses: actions/checkout@v4
          with:
            fetch-depth: 0
        - uses: Jason-Clark-FG/mirror-action-ng@main
          with:
            REMOTE: 'ssh://git@gitlab.com/spyoungtech/mirror-action-ng.git'
            GIT_SSH_PRIVATE_KEY: ${{ secrets.GIT_SSH_PRIVATE_KEY }}
            GIT_SSH_KNOWN_HOSTS: ${{ secrets.GIT_SSH_KNOWN_HOSTS }}

```

`GIT_SSH_KNOWN_HOSTS` is expected to be the contents of a `known_hosts` file.

Be sure you set the secrets in your repo secrets settings!

**NOTE:** if you prefer to skip hosts verification instead of providing a known_hosts file,
you can do so by using the `GIT_SSH_NO_VERIFY_HOST` input option. e.g.

```yaml
      steps:
        - uses: actions/checkout@v4
          with:
            fetch-depth: 0
        - uses: Jason-Clark-FG/mirror-action-ng@main
          with:
            REMOTE: git@gitlab.com/spyoungtech/mirror-action-ng.git
            GIT_SSH_PRIVATE_KEY: ${{ secrets.GIT_SSH_PRIVATE_KEY }}
            GIT_SSH_NO_VERIFY_HOST: "true"
```

WARNING: this setting is a compromise in security. Using known hosts is recommended.
