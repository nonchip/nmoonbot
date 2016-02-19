lanes = require"lanes".configure{
  protect_allocator: true
  verbose_errors: true
  on_state_create: ->
    require "moonscript"
}

tf_irc=lanes.gen "*", require "threads.irc"

last_behaviour=_G.arg and _G.arg[1] and "threads.behaviours.".._G.arg[1] or "threads.init_behaviour"
tf_behaviour=lanes.gen "*", (... using last_behaviour) -> (require last_behaviour)(...)

li_comm=lanes.linda!
li_ctrl=lanes.linda!

la_irc=tf_irc li_comm
la_behaviour=tf_behaviour li_comm, li_ctrl


ta_resurrect=lanes.gen "*", ((using li_ctrl)->
  while true
    li_ctrl\send "resurrectionPing", 1337
    k,v=li_ctrl\receive 2,"resurrectionPong"
    if k~="resurrectionPong" or v~=1337
      print "resurrection ping timeout or error: ", k, v
      li_ctrl\send "mainloop_cmd", {cmd:"reload"}
      print "reload command triggered."
)!

li_ctrl\set "mainloop_stayAlive", true
while true == li_ctrl\get "mainloop_stayAlive"
  k,v=li_ctrl\receive 1, "mainloop_cmd"
  if k == "mainloop_cmd"
    switch v.cmd
      when "reload"
        b=v.behaviour and ("threads.behaviours." .. v.behaviour) or last_behaviour
        print "loading behaviour:",b
        package.loaded[last_behaviour]=nil
        package.loaded[b]=nil
        la_behaviour\cancel 0, true, 1
        tf_behaviour=lanes.gen "*", (... using b) -> (require b)(...)
        la_behaviour=tf_behaviour li_comm, li_ctrl, b==last_behaviour
        last_behaviour=b
        print "done."
      when "reconnect"
        print "reconnecting irc…"
        package.loaded["threads.irc"]=nil
        la_irc\cancel 0, true, 1
        tf_irc=lanes.gen "*", require "threads.irc"
        la_irc=tf_irc li_comm
        print "done."
  k,v=li_comm\receive 1, "irc_err"
  if k == "irc_err"
    print "IRC ERROR:", unpack v
