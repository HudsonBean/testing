Please analyze this roblox tooling.

https://github.com/PepeElToro41/replecs/tree/main/demo


This is a tool called replecs that esentially helps replicate Entity Component System data from server to client in ROBLOX. This one is using Jecs (https://github.com/Ukendio/jecs). So my question can you analyze the demo project and explain through their setup to me? How do they initialize players? Is player a component, a tag, or an entity? Do they inititalize it on the client and network that to the server?

I want to implement something that will do this on my project. So that I can then tag the local player with things like "Health" and then have my @src/shared/Systems/HealthSystem.luau operate on it.