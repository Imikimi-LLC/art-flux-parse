###
This file exists to require flux, but only if it isn't already loaded.

This allows the client to load flux in web-worker mode (which avoids loading all of the art-engine).
###
require './namespace'
console.error "Please require 'art-flux' or 'art-flux/web_worker' before 'art-flux-parse'" unless Neptune.Art.Flux.Core
module.exports = Neptune.Art.Flux
