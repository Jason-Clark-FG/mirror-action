# FROM alpine/git@sha256:ec76d75a4b5367f16cf6dc859e23c06656761ad4dfcb1716c1800582ce05f5e8
FROM alpine/git@sha256:c818699b2927abbaacbbc5e5a593646989588c9b7f321055f6e571da140e43fe

RUN apk --no-cache add bash

LABEL "com.github.actions.name"="Mirror Repository"
LABEL "com.github.actions.description"="Automate mirroring of git commits to another remote repository, like GitLab or Bitbucket"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="green"

LABEL "repository"="https://github.com/Jason-Clark-FG/mirror-action"
LABEL "homepage"="https://github.com/Jason-Clark-FG/mirror-action"
LABEL "maintainer"="Jason Clark <jclark@factorsgroup.com>"

COPY entrypoint.sh /entrypoint.sh
COPY cred-helper.sh /cred-helper.sh
ENTRYPOINT ["/entrypoint.sh"]
