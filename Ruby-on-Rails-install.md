# Install Ruby and Rails on Ubuntu 22.04

```sh
## Open a terminal window

## Update the package list

sudo apt update

## Install dependencies

sudo apt install git curl autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev

## Install ZSH(You can use bash if you prefer, but ZSH is recommended for better experience.)

sudo apt install zsh

## Set ZSH as default shell(Optional, but recommended.)

chsh -s $(which zsh)

## Log out and log in again, or restart terminal

## Install RVM

curl -sSL https://get.rvm.io | bash -s stable

## Source RVM in ZSH config(Optional, but recommended.)

echo 'source $HOME/.rvm/scripts/rvm' >> ~/.zshrc

## Reload ZSH config(Optional, but recommended.)

source ~/.zshrc

## Install latest Ruby

rvm install ruby --latest

## Set Ruby as default

rvm use ruby --default

## Verify Ruby

ruby -v

## Install Rails

gem install rails

## Verify Rails

rails -v
```

## How to fix Error running '__rvm_make -j8'

Uninstall openssl@3 and install openssl@1.1

```sh
brew uninstall --ignore-dependencies openssl@3 
```
https://stackoverflow.com/questions/76815495/how-to-fix-error-running-rvm-make-j8
https://github.com/rvm/rvm/issues/5254

## How do I uninstall ruby and gems using RVM?

https://stackoverflow.com/questions/8868555/how-do-i-uninstall-ruby-and-gems-using-rvm

## Bundler: You must use Bundler 2 or greater with this lockfile

https://stackoverflow.com/questions/53231667/bundler-you-must-use-bundler-2-or-greater-with-this-lockfile