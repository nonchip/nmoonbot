class BaseBehaviour
  @host: ""
  @port: 0
  @nick: ""
  @user: ""
  @real: ""
  new: (@lirc,@lmain, reloading=false)=>
    if @@host=="" error "please set the behaviour's @host member"
    if @@port==0  error "please set the behaviour's @port member"
    if @@nick=="" error "please set the behaviour's @nick member"
    if @@user=="" error "please set the behaviour's @user member"
    if @@real=="" error "please set the behaviour's @real member"
    if not reloading
      @lirc\send "irc_cmd", {cmd: "connect", host: @@host, port: @@port}
      @tNICK @@nick
      @tUSER @@user, @@real
    @mainloop!
  send_irc: (msg)=> @lirc\send "irc_send", msg
  recv_irc: =>
    k,v=@lirc\receive 0.01, "irc_recv"
    if k=="irc_recv"
      return v
    return nil

  tNICK: (nick)=> @send_irc "NICK :"..nick
  tUSER: (user,real)=> @send_irc "USER "..user.." 0 * :"..real
  tPONG: (arg) => @send_irc "PONG :"..arg
  tJOIN: (chan) => @send_irc "JOIN :"..chan
  tPART: (chan, reason="bye") => @send_irc "PART "..chan.." :"..reason
  tPRIVMSG: (targ,msg) => @send_irc "PRIVMSG "..targ.." :"..msg

  rNOTICE: (src, targ, notice) =>
    print "NOTICE", src, notice
  rJOIN: (src, targ) =>
    print "JOIN",src, targ
  rPART: (src, targ, reason) =>
    print "PART",src, targ, reason
  rPRIVMSG: (src, targ, msg) =>
    print "PRIVMSG",src, targ, msg
  rMODE: (src, targ, flags, ...) =>
    print "MODE", src, targ, flags, ...
  rPING: (src, arg) =>
    @tPONG arg

  handle_command: (src, cmd, args)=>
    fun=@["r"..cmd]
    if fun
      status,err=pcall fun, @, src, unpack args
      if not status
        print "HANDLE_COMMAND_ERROR: ",err
  mainloop: =>
    while true
      k,v=@lmain\receive 0, "resurrectionPing"
      if k=="resurrectionPing"
        @lmain\send "resurrectionPong", v
      msg=@recv_irc!
      continue unless msg
      src=nil
      if msg\sub(1,1) == ":"
        i=msg\find" ",2 or msg\len!+1
        src=msg\sub(2,i-1)
        msg=msg\sub i+1
      i=msg\find" " or msg\len!+1
      cmd=msg\sub(1,i-1)
      msg=msg\sub i+1
      args={}
      while msg\len!>0 and msg\sub(1,1)~=":"
        i=msg\find" " or msg\len!+1
        table.insert args, msg\sub(1,i-1)
        msg=msg\sub i+1
      if msg\len!>0
        table.insert args, msg\sub 2
      @handle_command src, cmd, args
