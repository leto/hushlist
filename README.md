# Hushlist: Censorship Resistant Metadata-Minimizing Multi-Blockchain Communication

Hushlist uses the Hush cryptocoin blockchain, as well as other Zcash-fork privacy coin
blockchains to implement mailing-list style communication which inherit all of
the beautiful properties that Hush inherits from Bitcoin and Zcash.

# Requirements

Hushlist requires a computer with Perl 5.8+, and access to a Hush fullnode RPC server
which is often run on localhost. Hushlist supports all platforms that Hush currently
supports, which is Linux, Mac and Windows.

Sending shielded transactions (involving zaddrs) can be very resource
intensive, and at least 4GB of RAM is recommended, although 2GB may work on
some newer versions and platforms.

# Supported Blockchains

* HUSH
* TUSH  (HUSH testnet)
* Zcash (ZEC)
* TAZ   (ZEC testnet)
* Komodo (KMD) - planned

# Examples

    # create a new Hush contact
    hushlist contact add alice z1234...
    hushlist contact add bob z1456....

    # see an overview of your local Hushlists
    hushlist status

    # create a new private Hushlist, which exists locally only
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
it is currently in the `z_embedstring` branch:

    # make an already created private hushlist PUBLIC, i.e.
    # publish it's privkey to the blockchain. This costs HUSH, since
    # we need to send an xtn to the blockchain
    hushlist public listname

# How Is This Different Than Hush Messenger?

Hush Messenger has similar functions, but it more closely maps to "chat
program" versus "mailing list software". Messenger also has a different tech
stack (Javascript) and runs in the browser while Hushlist avoids the
convenience of browsers to reduce it's attack surface.

# License

GPLv3

