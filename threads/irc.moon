(comm)->
  _,err=pcall ->
    socket=require "socket"
    cl=nil
    while true
      k,v=comm\receive 0.001, "irc_cmd"
      if k=="irc_cmd"
        switch v.cmd
          when "connect"
            if cl
              cl\close!
            cl,err=socket.connect v.host, v.port
            if cl
              cl\settimeout 0.01
            else
              comm\send "irc_err", {"connect", v.host, v.port, err}
      if cl
        v,err=cl\receive "*l"
        if v~=nil
          --print "IRC> ",v
          comm\send "irc_recv", v
        elseif err~="timeout"
          comm\send "irc_err", {"receive", err}
        k,v=comm\receive 0, "irc_send"
        if k=="irc_send"
          --print "IRC< ",v
          cl\send v.."\r\n"
  print "IRC thread crash:",err
