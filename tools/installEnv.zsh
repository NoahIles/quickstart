#! /usr/bin/env zsh
# This Script installs a c++ development environment at the $install_location
# Requires:
#   - Macos (uses Homebrew)
#   - Zsh (should be installed on newer macs) linux folk might need to run a quick `apt install zsh` first 

# Usage: 
# /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/NoahIles/quickstart/devEnvs/tools/installEnv.sh)"

# Configuration Variables: 
INSTALL_LOCATION="$HOME/development"
TMP_DIR="$HOME/tmp"

# This Script Will Install the following dependecies on its own:
dependencies=(
  "git"
  "docker"
  "docker-compose"
  "visual-studio-code"
)

#-----------------------------------------------------------------------------------------------------
# installs dependencies if needed, use the installer passed in by parameter
#-----------------------------------------------------------------------------------------------------
install_dependencies() {
  #if no parameter is passed in then exit the function
  if [ -z "$1" ]; then
    echo "ERORR: No installer Selected" && return
  fi
  echo "using  $1  to install dependencies."
  for dependency in "${dependencies[@]}"; do
    if [[! command -v $dependency >/dev/null 2>&1]]; then
      echo "Installing $dependency"
      # $1 is the installer passed by parameter to the function ie: apt-get or yum
      $1 -y $dependency
    fi
  done
}

#-----------------------------------------------------------------------------------------------------
# Ask User for Confirmation
#-----------------------------------------------------------------------------------------------------
askUser() {
  echo "$1 (y,n), n is default"  
  read -r answer
  if [ $answer = "y" ] || [ $answer = "Y" ]; then
    return 0
  else
    return 1
  fi
}

#-----------------------------------------------------------------------------------------------------
# ask the user if they want to use homebrew to install dependencies
# if they say yes install homebrew (if needed) and all dependencies
#-----------------------------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then # Macos Detected
  echo ""
  msg="Do you want to install dependencies using Homebrew?"
  if  askUser $msg ; then
    if [ ! command -v brew >/dev/null 2>&1]; then   # homebrew is not installed
      echo "Installing Homebrew" # install homebrew
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      install_dependencies "brew install --cask" # install dependencies
    else
      brew update # Update Homebrew
    fi
    install_now="Homebrew is installed, install depenencies now?"
    if askUser $install_now; then
      install_dependencies "brew install --cask" # install dependencies
    else
      echo "Skipping Homebrew/Dependencies Install Please Make sure you install docker and vscode on your own."
    fi
  fi

elif [[ "$OSTYPE" == "linux"* ]]; then # Linux OS Detected
  echo "Your are running this script on Linux!"
  # check for apt
  if command -v apt >/dev/null 2>&1; then
    install_dependencies "sudo apt-get -y install" # install dependencies

  # if No apt check for yum
  elif command -v yum >/dev/null 2>&1; then
    install_dependencies "sudo yum install -y" # install dependencies
  else
    echo "You are running this script on a Linux system that does not have apt or yum installed."
    echo "Please install docker and vscode on your own."
  fi
else
  echo "Unsupported OS"
  exit 1
fi

#-----------------------------------------------------------------------------------------------------
# Creates a development directory in your home directory and clones the development environment repo If 
# git is not installed it currently fails   But it should be installed by the time the script gets here
#-----------------------------------------------------------------------------------------------------

if [ ! -f $HOME/.zsh_history ]; then #no local zsh history file
  touch $HOME/.zsh_history #create a local zsh history file
fi
# Check for repo to maintain support for updateing from older versions
if [ -d $INSTALL_LOCATION/.git ]; then # there is a git folder in the development directory
  repoExists=1
  update_repo="You Already have the repository would you like to try and update it?"
  if askUser $update_repo ; then
    cd $INSTALL_LOCATION
    git fetch && git pull
  else
    repoExists=0
    echo "Skipping update"
  fi
fi
#! Consider making this an elif?
if [ -d $INSTALL_LOCATION ] && [ ! repoExists ]; then
  clean_install="development folder exists would you like to clean install?"
  # echo "clean install is $clean"
  #? This is a hard clean install of the repo from scratch
  if askUser $clean_install; then
    echo "Rescueing Code if it Exists"
    #TODO Finish rescue code // clean install of repo
    find $INSTALL_LOCATION -type 'd' -name '*[^.*]*' -mindepth 1 -maxdepth 1 |
      xargs -I '{}' mv -rf {} $TMP_DIR
    find $INSTALL_LOCATION -type 'f' -name '*[^.*]*' -not -path "*readme*" -mindepth 1 -maxdepth 1 |
      xargs -I '{}' mv -rf {} $TMP_DIR
    #! un-comment this and figure out code rescue
    # rm -rf $INSTALL_LOCATION
  fi

fi

# If git exists use git clone otherwise curl
if [ -x "$(command -v git)" ]; then
  git clone --recursive --depth 1 --branch devEnvs --filter=blob:none https://github.com/NoahIles/quickstart.git $INSTALL_LOCATION
else
  echo "Git not installed. Install Failed"
fi
#! #TODO check if code (vscode) is installed to path or installed at all.
echo "Installing VSCode Extensions"
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
echo ""
echo "Download Complete Opening In VsCode Now to finish installing"
code -n $INSTALL_LOCATION/
#! Verify that this extension actually gets installed.