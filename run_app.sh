#!/bin/sh
set -eu

export APP_ID="emedia.maxperl_emedia_1.0.1"
export UBUNTU_APP_LAUNCH_ID="emedia.maxperl_emedia_1.0.1"

APP_NAME="emedia.maxperl"

APP_HOME="/home/phablet/.local/share/${APP_NAME}"
APP_CACHE="/home/phablet/.cache/${APP_NAME}"
APP_CONFIG="/home/phablet/.config/${APP_NAME}"

export XDG_DATA_HOME="$APP_HOME/.local/share"
export XDG_CACHE_HOME="$APP_CACHE"
export XDG_CONFIG_HOME="$APP_CONFIG"
export XDG_DATA_DIRS="$APP_DIR/share:/usr/local/share:/usr/share"
export ELM_CONFIG_DIR_XDG="$APP_DIR/share/elementary/config"
export XDG_CONFIG_DIRS="$APP_CONFIG:$APP_DIR/share/elementary/config:${XDG_CONFIG_DIRS:-}"
export XDG_RUNTIME_DIR="$APP_CACHE/run"
export PULSE_RUNTIME_PATH="/run/user/32011/pulse"

export ELM_PREFIX="$APP_DIR"
export E_PREFIX="$APP_DIR"
export ELM_BIN_DIR="$APP_DIR/bin"
export E_BIN_DIR="$APP_DIR/bin"
export ELM_LIB_DIR="$APP_DIR/lib/aarch64-linux-gnu"
export E_LIB_DIR="$APP_DIR/lib/aarch64-linux-gnu"
export ELM_DATA_DIR="$APP_DIR/share/elementary"
export E_DATA_DIR="$APP_DIR/share/elementary"
export ELM_LOCALE_DIR="$APP_DIR/share/locale"
export E_LOCALE_DIR="$APP_DIR/share/locale"

export LD_LIBRARY_PATH="$APP_DIR/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PERL5LIB="$APP_DIR/perl5:$APP_DIR/perl5/lib/perl5:${PERL5LIB:-}"

export EINA_LOG_BACKTRACE=0
#export GST_DEBUG="*:3"
export GST_PLUGIN_PATH="$APP_DIR/lib/gstreamer-1.0"
export QT_QPA_PLATFORM=xcb

exec "bin/perl" "$APP_DIR/UbuntuApp.pl" "$@" 
