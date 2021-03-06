package.path = './lib/?.lua;'
package.cpath = './lib/?.so;'

local protobuf = require "protobuf"
local chuck = require("chuck")
local socket = chuck.socket
local event_loop = chuck.event_loop.New()
local log = chuck.log

local addr = io.open("test/lua/addressbook.pb","rb")
local pb_buffer = addr:read "*a"
addr:close()

protobuf.register(pb_buffer)

local event_loop = chuck.event_loop.New()

local serverAddr = socket.addr(socket.AF_INET,"127.0.0.1",8010)

socket.stream.dial(event_loop,serverAddr,function (fd,errCode)
	if errCode then
		print("connect error:" .. errCode)
		return
	end
	local conn = socket.stream.socket(fd,4096)
	if conn then

		print("connect ok")

		local addressbook = {
			name = "Alice",
			id = 12345,
			phone = {
				{ number = "1301234567" },
				{ number = "87654321", type = "WORK" },
			}
		}
		--发送大量数据填满socket send buff,这样将导致触发chk_error_send_timeout
		for i = 1,100000 do
			local buff = chuck.buffer.New()
			local code = protobuf.encode("tutorial.Person", addressbook)
			buff:AppendStr(code)
			conn:Send(buff)
		end
		conn:Start(event_loop,function (data,errno)
			if data then 
				print("got response")
				conn:Close()
			else
				print("client disconnected " .. errno) 
				conn:Close()
			end
		end)
	end
end)

event_loop:WatchSignal(chuck.signal.SIGINT,function()
	print("recv SIGINT stop client")
	event_loop:Stop()
end)

event_loop:Run()