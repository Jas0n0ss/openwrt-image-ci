# Jas0n0ss OpenWrt — oh-my-bash (interactive shells only)
case $- in
  *i*) ;;
  *) return;;
esac

export OSH='/etc/oh-my-bash'

if [ ! -f "$OSH/oh-my-bash.sh" ]; then
  PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
  return
fi

OSH_THEME="minimal"
OMB_USE_SUDO=false

completions=(ssh)
aliases=(general)
plugins=()

# Skip slow / missing tools on router images
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

source "$OSH/oh-my-bash.sh"

# Post-login hint (full ASCII banner already shown by Dropbear /etc/banner)
_jas0n0ss_bash_motd() {
  _src=$(cat /etc/jas0n0ss-build-source 2>/dev/null || echo 'openwrt')
  _rel=$(grep '^DISTRIB_DESCRIPTION=' /etc/openwrt_release 2>/dev/null | cut -d= -f2- | tr -d "'\"")
  _ip=$(uci -q get network.lan.ipaddr 2>/dev/null || echo '10.10.10.1')
  printf '  [%s] LuCI: http://%s/  |  oh-my-bash  |  @Jas0n0ss\n' "$_src" "$_ip"
  [ -n "$_rel" ] && printf '  %s\n' "$_rel"
  printf '  Source: https://github.com/Jas0n0ss/openwrt-lede-builder\n\n'
}
_jas0n0ss_bash_motd

unset -f _jas0n0ss_bash_motd
