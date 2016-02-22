os=require "os"
BaseBehaviour=require "threads.base_behaviour"
mp = require 'MessagePack'
mp.set_number'float'
mp.set_array'with_hole'
mp.set_string'string'

loadDB= (name)->
  name=name..".db"
  f=io.open name, "r"
  return nil unless f
  str=f\read "*a"
  f\close!
  return nil unless str
  return mp.unpack(str)

saveDB= (name, val)->
  name=name..".db"
  str=mp.pack(val)
  return nil unless str
  f=io.open name, "w"
  return nil unless f
  f\write str
  f\close!

class extends BaseBehaviour
  @host: "irc.hackint.org"
  @port: 6667
  @nick: "kitten"
  @user: "kitten"
  @real: "github.com/nonchip/nmoonbot"
  @owner: "nonchip"

  new: (...)=>
    @handleBDSM.__init @
    super ...

  rNOTICE: (src, targ, notice) =>
    if src\sub(1,9)=="NickServ!"
      if notice\sub(1,28)=="This nickname is registered."
        print "identifying…"
        @tPRIVMSG "NickServ", "IDENTIFY "..require "kitten_nickserv_secret"
        return
      if notice\sub(1,26)=="You are now identified for"
        print "identified. joining #BDSM…"
        @tJOIN "#BDSM"
        return
    super src, targ, notice

  rPRIVMSG: (src, targ, msg) =>
    i=src\find"!"
    if not i or (i and src\sub(1,i-1)==@@nick)
      return super src, targ, msg
    snick=src\sub(1,i-1)
    msg=msg\gsub "^%s*(.-)%s*$", "%1"
    if targ=="#BDSM"
      @handleBDSM.__always @, snick, msg
      if msg\sub(1,1)=="!" and msg\sub(2,2)~="_"
        i=msg\find" " or msg\len!+1
        cmd=msg\sub(2,i-1)
        if type(@handleBDSM[cmd])=="function"
          @handleBDSM[cmd] @, snick, msg\sub(i+1)
    if snick==@@owner
      if msg\sub(1,7)=="!reload"
        @lmain\send "mainloop_cmd", {cmd:"reload"}
    super src, targ, msg

  handleBDSM:{

    __init: =>
      @seen=loadDB"seen" or {}
      @notice=loadDB"notice" or {}

    __always: (src, msg)=>
      @seen[src]=os.date"%c"
      saveDB "seen", @seen
      if @notice[src]
        for i=1, math.min #(@notice[src]),3
          n=table.remove @notice[src], 1
          @tPRIVMSG src, "[NOTICE] from "..(n.s)..": "..(n.m)
        saveDB "notice", @notice

    notice: (src, arg)=>
      i=arg\find" "
      return nil unless i
      to=arg\sub 1, i-1
      msg=arg\sub i+1
      @notice[to] or={}
      table.insert @notice[to], {s:src, m:msg}
      saveDB "notice", @notice

    seen: (src, nick)=>
      if @seen[nick]
        @tPRIVMSG "#BDSM", nick.." was last seen at "..@seen[nick]

  }
