# RFDF
I am still not happy with some of the code and structure in RFDF however it is made public so friends can use it.

RFDF has been battle tested in Project Flight with 60+ million visits and works perfectly as intended so feel free to use it, i personally like these types of frameworks more than ECS and i decided to make my own as a replacement for the module loader hell we had in Project Flights recode for an entire year.

# Usage
## Service
This is how i personally code the private function is for internal use and the public function is for other services to use its easy to see what is private and what is public just by checking if it is snake_case or PascalCase i personally like it.
```luau
--!strict
const ReplicatedStorage = game:GetService("ReplicatedService")
const RFDFTypes = ReplicatedStorage.RFDF.Types

local Service = {}
Service.__index = Service

function Service.new(StartupData: RFDFTypes.StartupData)
    local self = setmetatable({}, Service):: self
    self.RFDF = StartupData.RFDF

    self._private_function()
    
    return self
end

function Service._private_function()
    print("Hello World!")
end

function Service.Init(self: self)
    self.CharacterManager = self.RFDF:GetService("CharacterManager")
end

function Service.PublicFunction()
    print("Hello World!")
end

export type Service = typeof(Service) & {
    RFDF: RFDFTypes.RFDF,
    CharacterManager: RFDFTypes.CommonServiceFunctions & any,
}
type self = Service

return Service
```

## Endpoints
### Schemas and Network information
Internally i used a unsigned 8-bit integer for each endpoint to identify each endpoint in a batch this means there is only 255 endpoints u can have i personally thought that was a good amount, the tag is just for the interface so u know what is what. For Project Flight i made a spreadsheet for each endpoint, their path and type.

TLDR:
* 255 endpoints max
* every endpoint has a u8id (unsigned 8-bit integer) and a Tag which u can read in the interface

### Replicated Registries

For replicated registries we dont need a schema we just need a u8id and set the ClientAllowWrite boolean and ServerAllowWrite boolean.

I'm aware that the way i have done the registries is technically flawed because you cannot have one per client unless u manually make one directly with the network i have not thought of a fix yet.

Here is an example endpoint module
```luau
local Endpoint = {
	u8id = 0,
	Tag = script.Name,

	ClientAllowWrite = true, -- here we allow the server to write on the client
	ServerAllowWrite = false, -- here we can allow the client to write on the server
}

return Endpoint
```

Here is the API for replicated registries
```luau
local Endpoint = self.RFDF:RequireEndpoint("/Registry")
local Registry = Endpoint.Registry -- empty table from the endpoint to write at or read from

Endpoint:PromiseFilledRegistry(Timeout: number, Tries: number, Sleep: number) -- this yields until the registry is filled or the promise is timed out
Endpoint:Fetch() -- calls for client or server to send data back
Endpoint:Push(Targets: {Player}?) -- replicates all client to server or client(s)

Registry.Data = "Hello"
Endpoint:Push()

Registry = {Data = "Hello"}
Endpoint:Push()
```

### Remote Functions

Here is an example endpoint module
```luau
local Endpoint = {
	u8id = 0,
	Tag = script.Name,

	Timeout = nil,

	RequestSchema = Squash.string(),
	ReplySchema = Squash.string(),
}

return Endpoint
```

Here is the API for remote functions
```luau
const Players = game:GetService("Players")

local Endpoint = self.RFDF:RequireEndpoint("/RemoteFunction")

Endpoint:RequestFromServer(...: any) -- client - server - client
Endpoint:RequestFromClient(Target: Player?, ...: any) -- server - client - server

Endpoint:Hook(func: (...any) -> any) -- hook a reply function on the request receiving side

-- client - server - client
const reply_from_server = Endpoint:RequestFromServer("Oi!")
Endpoint:Hook(function(...)
    print(...)
    return "Yeah Cibao"
end)

-- server - client - server
const reply_from_client = Endpoint:RequestFromClient(Players.LinusKat, "Oi!")
Endpoint:Hook(function(...)
    print(...)
    return "Yeah Cibao"
end)
```

### Endpoints

Here is an example endpoint module
```luau
local Endpoint = {
	u8id = 0,
	Tag = script.Name,

	Schema = Squash.string(),
}

return Endpoint
```

Here is the API for endpoints
```luau
local Endpoint = self.RFDF:RequireEndpoint("/Endpoint")

-- Server
Endpoint:FireClient(Target: Player, ...: any)
Endpoint:FireClients(Targets: {Player}, ...: any)
Endpoint:FireAllClients(...: any)

-- Client
Endpoint:FireServer(...: any)
```

### Installation
Good question.