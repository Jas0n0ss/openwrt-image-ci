# Use bash + oh-my-bash for interactive SSH when root still has ash as login shell
if [ -n "${BASH_VERSION:-}" ] && [ "$(id -u)" = "0" ] && [ -f /root/.bashrc ]; then
  [ -f /root/.bashrc ] && . /root/.bashrc
fi
