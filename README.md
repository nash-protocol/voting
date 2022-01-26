# voting

## quickstart

```bash
git clone git@github.com:nash-protocol/voting.git
cd $( basename "${_}" .git )
curl https://docs.reach.sh/reach -o reach ; chmod +x reach
export REACH_VERSION=0.1.7
./reach compile --install-pkgs index.rsh
./reach compile "${_}"
```
