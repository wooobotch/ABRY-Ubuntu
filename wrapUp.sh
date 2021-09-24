#!/bin/bash

set -Eeo pipefail

echo -e $"*****************************************\n
*** Auto-Bootstrapper & Resource Yoke ***\n
***        Guided Installation        ***\n
*****************************************\n"

#Checks for the right distro and version before starting the process
check_linux (){
  echo -e "\aChecking for distro and version:"
  OS_ID=$(. /etc/os-release && echo "$ID")
  OS_VER=$(. /etc/os-release && echo "$VERSION_ID")

  if [ $OS_ID = ubuntu ]; then
    if [ \( "$OS_VER"=="20.04" \) ]; then
      echo "The OS matches the requierements." && sleep 1s
    else
      echo $"Newer version of the operating system is needed."
      exit 1
    fi
  else
    echo "Wrong distro, try Ubuntu 20.04"
    exit 1
  fi
}

#Puts dotfiles and other configuration files in their corresponding directories
dotfiles_mover () {
  echo -e "\aMoving configuration files..." && sleep 1s
  cp -r  $HOME/ABRY-Ubuntu/dotfiles/. $HOME
}

#Downloads suckless stuff from repo
get_unsucked () {
  echo -e "\aGetting repos..." && sleep 1s
  [ -d "$HOME/abry/repos" ] || mkdir -p $HOME/abry/repos
  cp repo-list $HOME/abry/repos
  cd $HOME/abry/repos
  for URL in $(xargs echo < repo-list); do
    REPO=$(echo $URL | rev | cut -d "/" -f 1 | rev)
    [ ! -d "$REPO" ] && git clone $URL
  done
  rm repo-list
  echo "The repos listed were downloaded!!" && sleep 1s
  cd -
}

#Calls make and make clean install
maker () {
  echo -e "\aMaking $1!" && sleep 1s
  cd $1
  make || echo "Couldn't 'make'"
  sudo make clean install || echo "$1 installtion aborted"
  cd -
}

#General installation function
installation () {
  echo -e "\aPackage and repositories installation:" && sleep 1s
  cd $HOME/ABRY-Ubuntu
  sudo apt-get update
  xargs sudo apt-get install -y --no-install-recommends < add-list
  cd $HOME/abry/repos
  for DIREC in $(xargs echo < repo-list); do
    [ -d "$(basename "$DIREC")" ] && maker "$(basename "$DIREC")"
  done
  cd -
}

#Uninstalation and obsolete package removal
clean_up (){
  echo -e "\aRevoming unnecesary reminders..." && sleep 1s
  cd $HOME/ABRY-Ubuntu
  xargs sudo apt-get remove < remove-list
  sudo apt-get autoremove
}

#Main function, it calls eerything else
main () {
  check_linux
  get_unsucked
  dotfiles_mover
  installation
  clean_up

  echo -e "Call \`sudo reboot\` to complete the setup.\n"
}


main
