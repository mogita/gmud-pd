-- POI Handler Registry and Handler Loader
-- Imports the registry and loads all handler files

-- Import the registry singleton
local registryModule = import("poi/handlers/registry")
local registry = registryModule.registry

-- Import and initialize handler files, passing them the registry
-- Each handler file exports a setup function that takes the registry
local interactiveSetup = import("poi/handlers/interactive")
interactiveSetup(registry)

local passageSetup = import("poi/handlers/passage")
passageSetup(registry)

local npcSetup = import("poi/handlers/npc")
npcSetup(registry)

-- Re-export registry module for backwards compatibility
return registryModule
