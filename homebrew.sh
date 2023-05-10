###################################################
#         HomeBrew setup script 
#         hli010@hotmail.com
###################################################

UNAME_MACHINE="$(uname -m)"

#Mac
if [[ "$UNAME_MACHINE" == "arm64" ]]; then
  #Apple 
  HOMEBREW_PREFIX="/opt/homebrew"
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
else
  #Inter
  HOMEBREW_PREFIX="/usr/local"
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
fi
HOMEBREW_CACHE="${HOME}/Library/Caches/Homebrew"

STAT="stat -f"
CHOWN="/usr/sbin/chown"
CHGRP="/usr/bin/chgrp"
GROUP="admin"


major_minor() {
  echo "${1%%.*}.$(x="${1#*.}"; echo "${x%%.*}")"
}

macos_version="$(major_minor "$(/usr/bin/sw_vers -productVersion)")"
TIME=$(date "+%Y-%m-%d %H:%M:%S")

JudgeSuccess()
{
    if [ $? -ne 0 ];then
        echo '\033[1;31mFAIL '$1'\033[0m'
        if [[ "$2" == 'out' ]]; then
          exit 0
        fi
    else
        echo "\033[1;32mSUCCESS\033[0m"

    fi
}

have_sudo_access() {
  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    /usr/bin/sudo -l mkdir &>/dev/null
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    echo "\033[1;31mWrong password!\033[0m"
  fi

  return "$HAVE_SUDO_ACCESS"
}


abort() {
  printf "%s\n" "$1"
  exit 1
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

execute() {
  if ! "$@"; then
    abort "$(printf "\033[1;31mFailed to run, try with root:sudo %s\033[0m" "$(shell_join "$@")")"
  fi
}

execute_sudo() 
{
  # local -a args=("$@")
  # if [[ -n "${SUDO_ASKPASS-}" ]]; then
  #   args=("-A" "${args[@]}")
  # fi
  if have_sudo_access; then
    execute "/usr/bin/sudo" "$@"
  else
    execute "sudo" "$@"
  fi
}

AddPermission()
{
  execute_sudo "/bin/chmod" "-R" "a+rwx" "$1"
  execute_sudo "$CHOWN" "$USER" "$1"
  execute_sudo "$CHGRP" "$GROUP" "$1"
}

CreateFolder()
{
    echo '-> Creating directory: ' $1
    execute_sudo "/bin/mkdir" "-p" "$1"
    JudgeSuccess
    AddPermission $1
}

RmAndCopy()
{
  if [[ -d $1 ]]; then
    DesktopDir=/Users/$(whoami)/Desktop/

    echo '   ---Backup old homebrew file to $DesktopDir...'
    if ! [[ -d $DesktopDir/Old_Homebrew/$TIME/$1 ]]; then
      mkdir -p $DesktopDir/Old_Homebrew/$TIME/$1
    fi
    cp -rf $1 $DesktopDir/Old_Homebrew/$TIME/$1
    echo "   ---$1 Backup Completed!"
  fi
  sudo rm -rf $1
}

RmCreate()
{
    RmAndCopy $1
    CreateFolder $1
}



git_commit(){
    git add .
    git commit -m "your del"
}

version_gt() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -gt "${2#*.}" ]]
}

version_ge() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -ge "${2#*.}" ]]
}

version_lt() {
  [[ "${1%.*}" -lt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -lt "${2#*.}" ]]
}

warning_if(){
  git_https_proxy=$(git config --global https.proxy)
  git_http_proxy=$(git config --global http.proxy)
  if [[ -z "$git_https_proxy"  &&  -z "$git_http_proxy" ]]; then
  echo "No git proxy found!"
  else
  echo "\033[1;33m
      Notes: found git proxy, if report error, run below commands:

              git config --global --unset https.proxy

              git config --global --unset http.proxy\033[0m
  "
  fi
}

