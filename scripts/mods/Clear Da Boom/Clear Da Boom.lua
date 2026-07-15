--[[
Name: Clear Da Boom
Author: Wobin
Date: 15/07/2026
Version: 1.0.0
Repository: https://github.com/Wobin/Clear-Da-Boom
--]]

local mod = get_mod("Clear Da Boom")
mod.version = "1.0.0"

local SOURCES = {
	hide_rumbler  = { "ogryn_thumper_grenade", "ogryn_thumper_grenade_instant" },
	hide_gauntlet = { "default_gauntlet_grenade", "special_gauntlet_grenade" },
	hide_grenades = { "ogryn_grenade_frag", "ogryn_box_cluster_frag" },
}

mod.SOURCES = SOURCES
mod.api = mod.api or {}

mod.api.build_cache = function(templates, sources, warn)
	local cache = {}

	for _, names in pairs(sources) do
		for i = 1, #names do
			local name = names[i]
			local template = templates[name]

			if template then
				cache[name] = {
					vfx          = template.vfx,
					scalable_vfx = template.scalable_vfx,
				}
			elseif warn then
				warn(name)
			end
		end
	end

	return cache
end

mod.api.apply = function(templates, cache, sources, enabled_map)
	for setting_id, names in pairs(sources) do
		local hide = enabled_map[setting_id]

		for i = 1, #names do
			local name = names[i]
			local template = templates[name]
			local original = cache[name]

			if template and original then
				if hide then
					template.vfx          = nil
					template.scalable_vfx = nil
				else
					template.vfx          = original.vfx
					template.scalable_vfx = original.scalable_vfx
				end
			end
		end
	end
end

local explosion_templates
local cache

local refresh = function()
	if not explosion_templates then
		return
	end

	local enabled = {
		hide_rumbler  = mod:get("hide_rumbler"),
		hide_gauntlet = mod:get("hide_gauntlet"),
		hide_grenades = mod:get("hide_grenades"),
	}

	mod.api.apply(explosion_templates, cache, SOURCES, enabled)
end

mod.on_all_mods_loaded = function()
	mod:info(mod.version)

	explosion_templates = require("scripts/settings/damage/explosion_templates")

	if not mod._vfx_originals then
		mod._vfx_originals = mod.api.build_cache(explosion_templates, SOURCES, function(name)
			mod:warning("explosion template not found: %s", name)
		end)
	end

	cache = mod._vfx_originals

	refresh()
end

mod.on_setting_changed = function()
	refresh()
end
