# Hushlist: Censorship Resistant Metadata-Minimizing Multi-Blockchain Communication


Examples of using Hush:

    # create a new Hush contact
    hushlist contact add alice z1234...
    hushlist contact add bob z1456....

    # see an overview of your local hushlist infoz
    hushlist status

    # create a new private hushlist, which exists locally only
    # and has no cost associated, since nothing is sent to the blockchain
    hushlist new listname

    # see the status of a list
    hushlist status listname
    hushlist add listname alice bob
    hushlist send listname "A beginning is the time for taking the most delicate care that the balances are correct."

    # send using a non-default chain
    hushlist send listname --chain tush "If wishes were fishes, we'd all cast nets. -- Stilgar"

    # show overview of lists and messages
    hushlist log

    # show most recent messages for listname
    hushlist log listname

    # donate 5 HUSH to the nice dev Duke Leto who write this software
    hushlist donate 5 hush

# In development commands

This will rely on z\_embedstring RPC which will hopefully be in the Hush 1.0.13 release,
it is currently in the `dev` branch:

    # make an already created private hushlist PUBLIC, i.e.
    # publish it's privkey to the blockchain. This costs HUSH, since
    # we need to send an xtn to the blockchain
    hushlist public listname

