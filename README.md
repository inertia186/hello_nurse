* Title: hello_nurse
* Tags: radiator ruby booster steemdev curation
* Notes: 

You should **not** use this bot **unless** you understand **exactly** what it does.  It requires your `active_key` and its use is not recommended.  Do not ask me for support if it sends all of your money somewhere.

As with all of my tools, this disclaimer applies:

```
Affirmer offers the Work as-is and makes no
representations or warranties of any kind
concerning the Work, express, implied,
statutory or otherwise, including without
limitation warranties of title,
merchantability, fitness for a particular
purpose, non infringement, or the absence of
latent or other defects, accuracy, or the
present or absence of errors, whether or not
discoverable, all to the greatest extent
permissible under applicable law.
```

---

#### Features

* YAML config.
  * `global`
    * `mode`
      * `head` - the last block
      * `irreversible` - (default) the block that is confirmed by 2/3 of all block producers and is thus irreversible!
  * `voting_rules`
    * `trigger_vote_weight` - exact voting amount to trigger a transfer.
    * `enable_comments` - enable or disable comments to trigger votes.
    * `max_vote_elapse` - to detect if the bots are offline (we don't want to transfer if the bot isn't voting).
  * `voters` - list of accounts to send transfers from after they vote.
  * `bots` - list of bots to send transfers to, separated by spaces

#### Overview

Hello Nurse (`hello_nurse`) is a bot that will transfer money to Dr. Otto bots when you vote a certain way.

For example, you can configure this bot to watch for 1% votes by you, and when that happens, transfer 2 SBD to your favorite pay-for-vote bot.  The memo will be set to the post that got a 1% upvote.

---

#### Install

To use this [Radiator](https://steemit.com/steem/@inertia/radiator-steem-ruby-api-client) bot:

##### Linux

```bash
$ sudo apt-get install ruby-full git openssl libssl1.0.0 libssl-dev
$ gem install bundler
```

##### macOS

```bash
$ gem install bundler
```

I've tested it on various versions of ruby.  The oldest one I got it to work was:

`ruby 2.0.0p645 (2015-04-13 revision 50299) [x86_64-darwin14.4.0]`

First, clone this gist and install the dependencies:

```bash
$ git clone https://github.com/inertia186/hello_nurse.git
$ cd hello_nurse
$ bundle install
```

Edit the configuration file `hello_nurse.yml`

```yaml
:global:
  :mode: irreversible

:voting_rules:
  :trigger_vote_weight: 2.00 %
  :enable_comments: true
  :max_vote_elapse: 600
  
:voters:
  :social:
    :active_key: 5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC
    :amount: 4.000 SBD
  :bad.account:
    :active_key: 5XXXBadWifXXXdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC
    :amount: 4.000 SBD

:bots: booster

:chain_options:
  :chain: steem
  :url: https://steemd.steemit.com
```

---

# Before you run it, make sure you and understand and fully control the voter accounts.  Any vote that matches the trigger weight will initiate a transfer.  Before running this bot, ensure all automated voting has been disabled or else this bot may transfer unexpected amounts.

---

Then run it:

```bash
$ ruby hello_nurse
```

Check here to see an updated version of this bot:

https://github.com/inertia186/hello_nurse

---

#### Upgrade

Typically, you can upgrade to the latest version by this command, from the original directory you cloned into:

```bash
$ git pull
```

Usually, this works fine as long as you haven't modified anything.  If you get an error, try this:

```
$ git stash --all
$ git pull --rebase
$ git stash pop
```

If you're still having problems, I suggest starting a new clone.

---

#### Troubleshooting

##### Problem: What does this error mean?

```
hello_nurse.yml:1: syntax error, unexpected ':', expecting end-of-input
```

##### Solution: You ran `ruby hello_nurse.yml` but you should run `ruby hello_nurse`.

---

##### Problem: Everything looks ok, but every time hello_nurse tries to post, I get this error:

```
`from_base58': Invalid version (RuntimeError)
```

##### Solution: You're trying to vote with an invalid key.

Make sure the `.yml` file `voters` item have the correct account name and WIF posting key.

##### Problem: The node I'm using is down.

Is there a list of nodes?

##### Solution: Yes, special thanks to @ripplerm.

https://ripplerm.github.io/steem-servers/

---

<center>
  <img src="http://i.imgur.com/O1IUQQH.png" />
</center>

See my previous Ruby How To posts in: [#radiator](https://steemit.com/created/radiator) [#ruby](https://steemit.com/created/ruby)

## Get in touch!

If you're using hello_nurse, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on STEEM and [SteemSpeak](http://discord.steemspeak.com).
  
## License

I don't believe in intellectual "property".  If you do, consider hello_nurse as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/) License.
