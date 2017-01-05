-- Start your normal program routines here 
print("Execute code")
dofile("config.lc")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid,password)
wifi.sta.connect()

tmr.alarm(3,2000,1,function()
        if(wifi.sta.status()==5) then
        ip, nm, gw = wifi.sta.getip()
        print(ip)
        print(nm)
        print(gw)
        tmr.stop(3)
        wifi.sta.setip({ip="192.168.1.150",netmask=nm,gateway=gw})
        end
end)

ssid=nil
password=nil

-- check if mqtt-client.lc exists before execute
if file.open("mqtt-client.lc") then
     file.close("mqtt-client.lc")
     dofile("mqtt-client.lc")
end

if srv~=nil then
  srv:close()
end

led1 = 3
led2 = 4
gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
srv=net.createServer(net.TCP,20)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local guestsPath = "/guestlist"
        local addGuestPath = "/addGuest"
        local deleteGuestPath = "/deleteGuest"
        local doorStatePath = "/doorState"
        local paramsTable = get_http_req (request)
        local uartWritten = false


        if paramsTable["PATH"]==guestsPath then
            uart.write(0, "GST_LST")
            uartWritten = true
        elseif paramsTable["PATH"]==doorStatePath then
            uart.write(0, "DOOR_STATE")
            uartWritten = true
        elseif paramsTable["PATH"]==addGuestPath then
            uart.write(0, "A_GST\n"..paramsTable["BODY"])
            uartWritten = true
        elseif paramsTable["PATH"]==deleteGuestPath then
            uart.write(0, "D_GST\n"..paramsTable["BODY"])
            uartWritten = true
        end

        if uartWritten then
        uart.on("data", "\r",
            function(data)
        local header = "HTTP/1.1 200 OK\r\n"     
          .."Content-Type: application/json\r\n"
          .."Content-Length: "
          ..string.len(data).."\r\n"
          .."\r\n"
        print(data)
        client:send(header..data);
        client:close();
        collectgarbage();
        if data=="quit\r" then
                uart.on("data") -- unregister callback function
                end
        end, 0)
        end

    end)
end)

function get_http_req (instr)
   local t = {}
   local first = nil
   local key, v, method, path, httpv, strt_fst_spc, end_fst_spc, strt_scd_spc, end_scd_spc
   local reads_body = false;


   for str in string.gmatch (instr, "([^\n]+)") do
      -- First line in the method and path
      if (first == nil) then
         first = 1
         strt_fst_spc, end_fst_spc = string.find (str, "([ ]+)")
         strt_scd_spc, end_scd_spc = string.find (str, "([ ]+)", end_fst_spc + 1)
        
         method = trim (string.sub (str, 0, strt_fst_spc))
         path = trim (string.sub (str, strt_fst_spc, strt_scd_spc))
         httpv = trim (string.sub (str, end_scd_spc))

         t["METHOD"] = method
         t["PATH"] = path
         t["HTTPV"] = httpv
      else -- Process and reamaining ":" fields

         if(reads_body)then
            t["BODY"] = str
            reads_body = false
         end
         
         if(str=="\r")then
            reads_body = true
         end
         
         strt_ndx, end_ndx = string.find (str, "([^:]+)")
         if (end_ndx ~= nil) then
            v = trim (string.sub (str, end_ndx + 2))
            key = trim (string.sub (str, strt_ndx, end_ndx))
            t[key] = v
         end
      end
   end

   return t
end

function trim (s)
  return (s:gsub ("^%s*(.-)%s*$", "%1"))
end
