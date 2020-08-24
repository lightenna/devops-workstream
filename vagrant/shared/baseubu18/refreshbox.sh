# update source box
vagrant box update
# copy to local repo
vagrant up --provision
# then package up, delete packaging copy and VM that spawned it
vagrant package --output baseubu18.box && \
    vagrant box add --force baseubu18 baseubu18.box && \
    rm -f baseubu18.box && \
    vagrant destroy -f
# clean up local copy
rm -rf .vagrant
