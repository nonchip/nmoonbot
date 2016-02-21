#!/bin/zsh
cd "$(dirname "$(readlink -f "$0")")"

if [[ "_$1" = "_-d" ]]
  then shift 1

read -d '' cmd <<END
  gdb -ex=r --args \$NMLT_ROOT'/bin/luajit' -e 'package.path="'\$NMLT_ROOT'/share/lua/5.1/?.lua;'\$NMLT_ROOT'/share/lua/5.1/?/init.lua;"..package.path; package.cpath="'\$NMLT_ROOT'/lib/lua/5.1/?.so;"..package.cpath' -e 'local k,l,_=pcall(require,"luarocks.loader") _=k and l.add_context("moonscript","0.4.0-1")' \$NMLT_ROOT'/lib/luarocks/rocks/moonscript/0.4.0-1/bin/moon' init.moon "$@"
END

lib/nMoonLib/.run sh -c "$cmd"

else

lib/nMoonLib/moon init.moon "$@"

fi
