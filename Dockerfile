FROM alpine/git:v2.47.2

RUN apk --no-cache add bash

LABEL "com.github.actions.name"="Mirror Repository"
LABEL "com.github.actions.description"="Automate mirroring of git commits to another remote repository, like GitLab or Bitbucket"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="green"

LABEL "repository"="https://github.com/Jason-Clark-FG/mirror-action-ng"
LABEL "homepage"="https://github.com/Jason-Clark-FG/mirror-action-ng"
LABEL "maintainer"="Jason Clark <jclark@factorsgroup.com>"

COPY entrypoint.sh /entrypoint.sh
COPY cred-helper.sh /cred-helper.sh
ENTRYPOINT ["/entrypoint.sh"]
