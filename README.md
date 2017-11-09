# Hushlist: Censorship Resistant Communication

    # create a new Hush contact
    hushlist contact add alice z123
    hushlist contact add bob z456

    # see an overview of your local hushlist infoz
    hushlist status

    # create a new private hushlist, which exists locally only
    # and has no cost associated, since nothing is sent to the blockchain
    hushlist new listname

    # make an already created private hushlist PUBLIC, i.e.
    # publish it's privkey to the blockchain. This costs HUSH, since
    # we need to send an xtn to the blockchain
    hushlist public listname

    hushlist status listname
    hushlist add listname alice bob
    hushlist send listname "A beginning is the time for taking the most delicate care that the balances are correct."

    # send using a non-default chain
    hushlist send listname --chain tush "If wishes were fishes, we'd all cast nets."

    # donate 5 HUSH to the nice devs who write this software
    hushlist donate 5 hush

