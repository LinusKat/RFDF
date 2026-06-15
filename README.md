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
Internally i used a 8 byte integer for each endpoint to identify each endpoint in a batch this means there is only 255 endpoints u can have i personally thought that was a good amount, the tag is just for the interface so u know what is what. For Project Flight i made a spreadsheet for each endpoint, their path and type.

TLDR:
* 255 endpoints max
* every endpoint has a u8id (8 byte integer) and a Tag which u can read in the interface

### Replicated Registries

### Remote Functions

### Endpoints