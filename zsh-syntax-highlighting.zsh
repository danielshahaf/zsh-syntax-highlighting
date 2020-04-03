# -------------------------------------------------------------------------------------------------
# Copyright (c) 2016-2020 zsh-syntax-highlighting contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------

# Welcome, reader.  The following code is designed to be run with the user's
# setopt's in effect, whatever they are.  That means we can't use some
# syntaxes.  We also implement anonymous functions with arguments the hard way,
# to support older zsh's.
#
# Options to beware of include:
#   functionargzero
#   ksharrays
#   posixbuiltins
#   ⋮

# First of all, ensure predictable parsing.
typeset zsh_highlight__aliases="$(builtin alias -Lm '[^+]*')"
# In zsh <= 5.2, aliases that begin with a plus sign ('alias -- +foo=42')
# are emitted by `alias -L` without a '--' guard, so they don't round trip.
#
# Hence, we exclude them from unaliasing:
builtin unalias -m '[^+]*'

# Use an anonymous function to avoid leaking variables.
local -a zsh_highlight__argv; zsh_highlight__argv=( "$@" )
() {
  set -- "${zsh_highlight__argv[@]}"
  
  # Second of all, save the user's options in $zsyh_user_options.
  local -A zsyh_user_options
  if zmodload -e zsh/parameter; then
    zsyh_user_options=("${(kv)options[@]}")
  else
    local canonical_options onoff option raw_options
    raw_options=(${(f)"$(emulate -R zsh; set -o)"})
    canonical_options=(${${${(M)raw_options:#*off}%% *}#no} ${${(M)raw_options:#*on}%% *})
    for option in "${canonical_options[@]}"; do
      [[ -o $option ]]
      case $? in
        (0) zsyh_user_options+=($option on);;
        (1) zsyh_user_options+=($option off);;
        (*) # Can't happen, surely?
            echo "zsh-syntax-highlighting: warning: '[[ -o $option ]]' returned $?"
            ;;
      esac
    done
  fi
  typeset -r zsyh_user_options
  
  # The following parameter expansion is a functionargzero-resistant spelling of "${0:h}".
  source "${${(%):-%N}:h}"/driver.zsh "$@"
}
unset zsh_highlight__argv

# Restore the aliases we unned
eval "$zsh_highlight__aliases"
builtin unset zsh_highlight__aliases

# Set $?.
builtin return 0
