os=require "os"
BaseBehaviour=require "threads.base_behaviour"
mp = require 'MessagePack'
mp.set_number'float'
mp.set_array'with_hole'
mp.set_string'string'

cutWord=(str)->
  i,j= if str\sub(1,1)=="\""
    2, str\find "\"",2,true
  else
    1, str\find " ",1,true
  return str unless i and j
  word=str\sub i, j-1
  str=str\sub j+i
  str=nil unless str\len!>0
  return word, str

iCutWord=(str)->
  tmp=str
  return ->
    return nil unless tmp
    word,tmp=cutWord tmp
    return word

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
    i=src\find"!",1,true
    if not i or (i and src\sub(1,i-1)==@@nick)
      return super src, targ, msg
    snick=src\sub(1,i-1)
    msg=msg\gsub "^%s*(.-)%s*$", "%1"
    if targ=="#BDSM"
      @handleBDSM.__always @, snick, msg
      if msg\sub(1,1)=="!" and msg\sub(2,2)~="_"
        i=msg\find(" ",1,true) or msg\len!+1
        cmd=msg\sub(2,i-1)
        if type(@handleBDSM[cmd])=="function"
          @handleBDSM[cmd] @, snick, msg\sub(i+1)
    if snick==@@owner
      if msg\sub(1,7)=="!reload"
        @lmain\send "mainloop_cmd", {cmd:"reload"}
      if msg\sub(1,7)=="!reconnect"
        @lmain\send "mainloop_cmd", {cmd:"reconnect"}
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
        num=#(@notice[src])
        for i=1, math.min num,3
          n=table.remove @notice[src], 1
          @tPRIVMSG src, "[NOTICE] ("..i.."/"..num..") from "..(n.s)..": "..(n.m)
        saveDB "notice", @notice

    notice: (src, arg)=>
      to,msg=cutWord arg
      @notice[to] or={}
      table.insert @notice[to], {s:src, m:msg}
      saveDB "notice", @notice

    callvote: (src, msg)=>
      return nil if @votes
      @voteReason,msg=cutWord msg
      @voteOwner=src
      @voted={}
      @votes= if not msg
        {{"Yes",0},{"No",0}}
      else
        [{w,0} for w in iCutWord msg]
      @tPRIVMSG "#BDSM", src.." called a vote: "..@voteReason
      for k,v in ipairs @votes
        @tPRIVMSG "#BDSM", "  ["..k.."] "..v[1]

    vote: (src, msg)=>
      return nil unless @votes
      n=tonumber msg
      return nil unless n>0
      return nil unless n<=#@votes
      return nil if @voted[src]
      @votes[n][2]+=1
      @voted[src]=true
      @tPRIVMSG "#BDSM", src.." voted for: "..@voteReason.." : "..@votes[n][1]

    endvote: (src,msg)=>
      return nil unless @votes
      return nil if @voteOwner~=src and src~=@@owner
      @tPRIVMSG "#BDSM", "vote results: "..@voteReason
      table.sort @votes, (a,b)-> a[2]>b[2]
      for k,v in ipairs @votes
        @tPRIVMSG "#BDSM", "  ["..v[2].."] "..v[1] if v[2]>0
      @votes=nil

    seen: (src, nick)=>
      if @seen[nick]
        @tPRIVMSG "#BDSM", nick.." was last seen at "..@seen[nick]

  }
