# update source box
vagrant box update
# copy to local repo
vagrant up --provision
# then package up, delete packaging copy and VM that spawned it
vagrant package --output baseco7.box && \
    vagrant box add --force baseco7 baseco7.box && \
    rm -f baseco7.box && \
    vagrant destroy -f
# clean up local copy
rm -rf .vagrant
