
ssid = "ESP" ..node.chipid()
psw  = "espconfig"

-- If GPIO0 changes during the countdown, launch config
gpio.mode(3, gpio.INT)
gpio.trig(3,"both",function()
     tmr.stop(0)
     dofile("run_config.lua")
end)
     
local countdown = 5


tmr.alarm(0,1000,1,function()
     print(countdown)
     countdown = countdown -1 
     if (countdown == 0) then
          gpio.mode(3,gpio.FLOAT)
          tmr.stop(0)
          if file.open("config.lc","r") then
               print("Enter program mode")
               dofile("run_program.lua")
          else
          	print("Enter configuration mode")
          	dofile("run_config.lua")
          end
     end
end)


