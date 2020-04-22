# copy to local repo
# then package up
# then delete packaging copy and VM that spawned it
vagrant up --provision
vagrant package --output baseco7.box && \
    vagrant box add --force baseco7 baseco7.box && \
    rm -f baseco7.box && \
    vagrant destroy -f
