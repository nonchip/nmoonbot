BaseBehaviour=require "threads.base_behaviour"
class extends BaseBehaviour
  @host: "irc.hackint.org"
  @port: 6667
  @nick: "nmoonbot"
  @user: "nmoonbot"
  @real: "github.com/nonchip/nmoonbot"
  @owner: "nonchip!~quassel@vm1.nonchip.de"
  rPRIVMSG: (src, targ, msg)=>
    i=msg\find" "
    if src==@@owner and targ==@@nick and i
      cmd=msg\sub 1, i-1
      arg=msg\sub i+1
      if cmd=="behave"
        @lmain\send "mainloop_cmd", {cmd:"reload", behaviour: arg}
        return
    super src, targ, msg
