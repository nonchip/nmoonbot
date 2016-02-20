lanes = require"lanes".configure{
  protect_allocator: true
  verbose_errors: true
  on_state_create: ->
    require "moonscript"
}

tf_irc=lanes.gen "*", require "threads.irc"

last_behaviour=_G.arg and _G.arg[1] and "threads.behaviours.".._G.arg[1] or "threads.init_behaviour"
tf_behaviour=lanes.gen "*", (b, ...) ->
  stat,mod_or_err=pcall require,b
  if not stat
    return print "BEHAVIOUR REQUIRE ERR:", mod_or_err
  stat,err=pcall mod_or_err, ...
  if not stat
    print "BEHAVIOUR CALL ERR:", err

li_comm=lanes.linda!
li_ctrl=lanes.linda!

la_irc=tf_irc li_comm
la_behaviour=tf_behaviour last_behaviour, li_comm, li_ctrl


tf_resurrect=lanes.gen "*", (li)->
  while true
    if io.open "/dev/shm/nmoonbot_resurrect", "r"
      print "resurrect file found, triggering reload."
      li\send "mainloop_cmd", {cmd:"reload"}
      os.remove "/dev/shm/nmoonbot_resurrect"
    li\send "resurrectionPing", 1337
    k,v=li\receive 2,"resurrectionPong"
    if k~="resurrectionPong" or v~=1337
      print "resurrection ping timeout or error: ", k, v
      li\send "mainloop_cmd", {cmd:"reload"}
      print "reload command triggered."

ta_resurrect=tf_resurrect li_ctrl

li_ctrl\set "mainloop_stayAlive", true
while true == li_ctrl\get "mainloop_stayAlive"
  k,v=li_ctrl\receive 1, "mainloop_cmd"
  if k == "mainloop_cmd"
    switch v.cmd
      when "reload"
        b=v.behaviour and ("threads.behaviours." .. v.behaviour) or last_behaviour
        print "loading behaviour:",b
        la_behaviour\cancel 0, true, 1
        la_behaviour=nil
        package.loaded[last_behaviour]=nil
        package.loaded[b]=nil
        collectgarbage!
        la_behaviour=tf_behaviour b, li_comm, li_ctrl, b==last_behaviour
        last_behaviour=b
        print "done."
      when "reconnect"
        print "reconnecting irc…"
        la_irc\cancel 0, true, 1
        la_irc=nil
        package.loaded["threads.irc"]=nil
        collectgarbage!
        tf_irc=lanes.gen "*", require "threads.irc"
        la_irc=tf_irc li_comm
        print "done."
  k,v=li_comm\receive 1, "irc_err"
  if k == "irc_err"
    print "IRC ERROR:", unpack v
