-- compile this module if you have memory issues

-- GPIO0 resets the module
gpio.mode(3, gpio.INT)
gpio.trig(3,"both",function()
    file.remove('config.lc')
    node.restart()
end)
     
-- read previous config
if file.open("config.lc") then
     file.close("config.lc")
     dofile("config.lc")
end


local unescape = function (s)
     s = string.gsub(s, "+", " ")
     s = string.gsub(s, "%%(%x%x)", function (h)
          return string.char(tonumber(h, 16))
         end)
     return s
end

print("Get available APs")
wifi.setmode(wifi.STATION) 
wifi.sta.getap(function(t)
    available_aps = "" 
    if t then 
        local count = 0
        for k,v in pairs(t) do 
            ap = string.format("%-10s",k) 
            ap = trim(ap)
            available_aps = available_aps .. "<option value='".. ap .."'>".. ap .."</option>"
            count = count+1
            if (count>=10) then break end
        end 
        available_aps = available_aps .. "<option value='-1'>---hidden SSID---</option>"
        setup_server()
    end
end)

function setup_server()
    uart.on("data", "\r",function(data)
    local line = nil    
    local WIFI_CONFIGURATION_TAG = "WIFI_CONFIGURATION_TAG"
    local wifissID = nil;
    local wifiPassword = nil;
        for str in string.gmatch (data, "([^\n]+)") do
            if (line == nil) then
                if(str==WIFI_CONFIGURATION_TAG) then
                    line = 1
                end
            elseif(line==1) then
                wifissID = str; 
                print(wifissID);
                line=2;
            elseif(line == 2) then
                wifiPassword = str;
                print(wifiPassword);
                break
            end
        end

        if (line ~= nil) then
                print("Writing configuration")
                file.open("config.lua", "w")
                file.writeline('ssid = "' .. wifissID .. '"')
                file.writeline('password = "' .. wifiPassword .. '"')
                file.close()
                node.compile("config.lua")
                file.remove("config.lua")
                node.restart();
        end

        if data=="quit\r" then
        uart.on("data") -- unregister callback function
        end
        
    end, 0)
end

function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end
