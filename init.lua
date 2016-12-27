function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        -- dofile("application.lua")
    end
end

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.setip({ip="192.168.1.150",netmask="255.255.255.0",gateway="192.168.1.1"})
wifi.sta.config("TP-LINK", "tencorcecho")
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default
tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        tmr.stop(1)
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 3 seconds to abort")
        print("Waiting...")
        tmr.alarm(0, 3000, 0, startup)
    end
end)


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
        local guestsPath = "/guestlist";
        local addGuestPath = "/addGuest";
        local paramsTable = get_http_req (request)


        if paramsTable["PATH"]==guestsPath then
            uart.write(0, "WIFI_TAG_GUESTLIST_REQUEST")
            uart.on("data", "\r",
                function(data)
                print("receive from uart:", data)
            local header = "HTTP/1.1 200 OK\r\n"     
              .."Content-Type: application/json\r\n"
              .."Content-Length: "
              ..string.len(data).."\r\n"
              .."\r\n"
            client:send(header..data);
            client:close();
            collectgarbage();
                if data=="quit\r" then
                    uart.on("data") -- unregister callback function
                    end
            end, 0)
        end

        
        if paramsTable["PATH"]==addGuestPath then
            uart.write(0, "WIFI_TAG_ADD_GUEST_REQUEST\n"..paramsTable["BODY"])
            uart.on("data", "\r",
                function(data)
--            local data = "{\"id\":4,\"name\":\"guest4\",\"key\":\"key4\"}";
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
