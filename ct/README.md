
## To create a zerotier ct
```
export GITHUB_BRANCH=test && \
        source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/ct/ct_create_zerotier.sh) 000
```

## To create a vanilla ct providing: ct_id ct_hostname ct_description
```
export GITHUB_BRANCH=test && \
    source <(wget --quiet -O - https://raw.githubusercontent.com/panchuz/setup_linux/$GITHUB_BRANCH/ct_create.sh) ct_id ct_hostname ct_description
```