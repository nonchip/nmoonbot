lanes = require"lanes".configure{
  protect_allocator: true
  verbose_errors: true
}

tf_irc=lanes.gen "*", require "threads.irc"
tf_behaviour_Sklavin=lanes.gen "*", require "threads.behaviours.Sklavin"

li_comm=lanes.linda!
li_ctrl=lanes.linda!

la_irc=tf_irc li_comm
la_behaviour=tf_behaviour_Sklavin li_comm, li_ctrl

li_ctrl\set "mainloop_stayAlive", true
while true == li_ctrl\get "mainloop_stayAlive"
  k,v=li_ctrl\receive 10, "mainloop_cmd"
  if k == "mainloop_cmd"
    switch v.cmd
      when "reload"
        print "reloading behaviour…"
        package.loaded["threads.behaviours.Sklavin"]=nil
        tf_behaviour_Sklavin=lanes.gen "*", require "threads.behaviours.Sklavin"
        la_behaviour\cancel 0, true, 1
        la_behaviour=tf_behaviour_Sklavin li_comm, li_ctrl
      when "reconnect"
        print "reconnecting irc…"
        package.loaded["threads.irc"]=nil
        tf_irc=lanes.gen "*", require "threads.irc"
        la_irc\cancel 0, true, 1
        la_irc=tf_irc li_comm
