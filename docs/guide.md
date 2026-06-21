---
title: Guide
sidebar_position: 3
---
# Guide

## Services

This is how services are personally setup. Private functions are declared with snake_case, and public functions are pascalCase.
RFDF will the CommonServiceFunctions of this service, .new and .Init. It passes StartupData as an argument for Service.new() which includes the RFDF instance, which you assign.
It then passes the service object to .Init(), which you can then initialize the service.

```lua
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

### Schemas and Network Information
Each endpoint is identified with a u8id (unsigned 8-bit integer), which means there are are maxiumum of 225 endpoints. Each 
endpoint also has a tag which you can read in the interface. Each schema in an endpoint requires you to use [Squash](https://github.com/Data-Oriented-House/Squash/).
Any fields you will not use can be deleted, rather than assigning nil.

Endpoints are located in `RFDF/Network`, which also includes a EndpointTemplate. You can create folders in this directory
to organise your endpoints, you will can you adjust the path when requiring them. Here is an example of an endpoint:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = require(ReplicatedStorage.RFDF._network_packages.Server)
local Squash = require(ReplicatedStorage.RFDF._packages.Squash)

local Endpoint = {
	u8id = 0, -- // 0 --> 225. This must be unique, you cannot share a u8id with another endpoint.
	Tag = script.Name, --  // Readable tag for the endpoint which you can read in the interface.

	ClientAllowWrite = nil, -- // Only add if it is a registry. When true the SERVER can write to CLIENT data
	ServerAllowWrite = nil, -- // Only add if it is a registry. When true the CLIENT can write to SERVER data

	Timeout = nil, -- // Only add if its a remote funciton, this is a promise timout after amount of time in seconds.

	RequestSchema = nil, -- // Only add if its a remote function
	ReplySchema = nil, -- // Only add if its a remote function
	Schema = nil, -- // Only add if its a normal endpoint to send reliable data with no packet loss 
}

return Endpoint

```