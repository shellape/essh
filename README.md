# essh - pass your local environment to your ssh remote host

## Purpose of essh
essh is a ssh wrapper which provides two main features:

* Invoke an interactive bash with your locally defined rc files (bashrc, vimrc, ...) on the ssh remote host.
* Try to start every ssh session within a gnu screen session by default (if available on the remote host).

## Builtin help
```
$> essh -h
essh - Pass your local environment to your ssh remote host.

Usage: essh [-h|--help|help] [-ns|--no-screen] <put your usual ssh parameters here>

```

## How it works
* essh uses ssh multiplexing. So for each ssh target host essh establishes one ssh master connection which is reused for further ones.
* essh pipes a tar ball of your locally defined rc files to the remote host via ssh.
* essh finally establishes a ssh connection executing a screen session (by default) with your locally defined screenrc.
  (If screen is not available or disabled by user an interactive bash will be invoked with your locally defined bashrc.core.)

## Example
```
essh example.org
```
This would result in an established ssh session inside a screen session (if available on the remote host).

To clarify what processes are started here an excerpt of ps output (as process tree) of the remote host:
```
# With screen:
/usr/sbin/sshd -D
 \_ sshd: root@pts/2    
     \_ bash -c export REMOTE_RC_DIR=/var/tmp/.essh; screen -c /var/tmp/.essh/screenrc
         \_ screen -c /var/tmp/.essh/screenrc
             \_ SCREEN -c /var/tmp/.essh/screenrc
                 \_ /bin/bash /var/tmp/.essh/shell-wrapper
                     \_ /bin/bash --rcfile /var/tmp/.essh/bashrc.core
                         \_ ps faux

# Without screen:
/usr/sbin/sshd -D
 \_ sshd: root@pts/2    
     \_ bash -c export REMOTE_RC_DIR=/var/tmp/.essh; bash --rcfile /var/tmp/.essh/bashrc.core
         \_ bash --rcfile /var/tmp/.essh/bashrc.core
             \_ ps faux

```
Consider that on different distributions the process tree can look slightly different.

## Preliminary considerations
Although it may not be obvious at first glance when starting bash, calling sudo or su the user environment is involved essentially.

Most of the time users are not really aware about that.

As the goal is to use the locally defined rc files there are some essential modifications in bashrc.core to make the environment behave like the user is used to.

## Installation
```
cd essh/bin
./install -i
INCLUDE_CONF=~/.essh_include.conf
test -e $INCLUDE_CONF || ./gen-include.sh -w > $INCLUDE_CONF
```

## Usage
```
Simply change to $ESSH_RC_DIR you saw in the output of the ./install script the step before and your are ready to start.

essh <put your usual ssh parameters here>
```

## Customization
essh has some variables you can modify in ~/.essh_include.conf.

## Q/A

### What is the essh indicator
When you login you'll see this line:
```
::essh::+s
```
This indicates you logged in via essh. "+s" means you're within a screen session, "-s" you're not.

Further on there are two environment variables when using essh:

```
$REMOTE_RC_DIR
$ESSH
```

### Which files should I use to put my custom bash aliases, bash functions in?

* Generally you should put your stuff to bashrc.user which gets sourced by bashrc.core
* Also feel free to modify vimrc and screenrc (except the line starting with "shell") to your needs.

### Are there files I should keep unchanged?

* YES! There should be no reason to modify bashrc.core, cleanup and shell-wrapper.

### Why should I keep this files unchanged?

* bashrc.core brings some really necessary stuff to force your env to behave like you are used to even if it may not look like that at first glance.
* cleanup ensures your REMOTE_RC_DIR gets removed on logout and other  situations.
* shell-wrapper is called from screenrc to enforce the use of bash with the custom bashrc file. (There might be a more elegant way for this task.)

### What is the variable REMOTE_RC_DIR for?

* REMOTE_RC_DIR defines where your locally defined rc files are stored on the remote system.
* REMOTE_RC_DIR is an environment variable which gets exported in essh itself or in include config.
* REMOTE_RC_DIR can be referenced within your different rc files for convenience purpose.

### How would I add a favorite command including the rc files being available via essh?

Let's look what we needed to achive this with vim. (You can adopt this approach to your favorite commands.)

```
cd ~/.essh.d
# Create your vimrc.
vim vimrc
# Add the correspondig bash alias to the bashrc.
echo 'alias vi="vim -u $REMOTE_RC_DIR/vimrc"' >> bashrc.user

That's it! :) Now you can use your locally defined vimrc on every remote host.
```

### How to debug?

PS4 is set to give some more informative debug output. Thus simply use "bash -x essh ....".

### How to use essh with ossh?

Actually there is only one additional ossh config line necesseary. Buzzword SSH_STRIP_EXPR.
