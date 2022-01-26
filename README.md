# voting

## quickstart

```bash
git clone git@github.com:nash-protocol/voting.git
cd $( basename "${_}" .git )
curl https://docs.reach.sh/reach -o reach ; chmod +x reach
reach() { REACH_VERSION=0.1.7 ./reach compile "${@}" ; }
reach compile --install-pkgs index.resh
reach compile "${_}"
```
