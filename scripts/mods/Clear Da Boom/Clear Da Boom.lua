--[[
Name: Clear Da Boom
Author: Wobin
Date: 16/07/2026
Version: 1.0.1
Repository: https://github.com/Wobin/Clear-Da-Boom
--]]

local mod = get_mod("Clear Da Boom")
mod.version = "1.0.1"

local SOURCES = {
	hide_rumbler  = { "ogryn_thumper_grenade", "ogryn_thumper_grenade_instant" },
	hide_gauntlet = { "default_gauntlet_grenade", "special_gauntlet_grenade" },
	hide_grenades = { "ogryn_grenade_frag", "ogryn_box_cluster_frag" },
}

mod.SOURCES = SOURCES
mod.api = mod.api or {}

mod.api.build_hidden_set = function(sources, enabled_map)
	local hidden = {}

	for setting_id, names in pairs(sources) do
		if enabled_map[setting_id] then
			for i = 1, #names do
				hidden[names[i]] = true
			end
		end
	end

	return hidden
end

mod.api.should_hide = function(explosion_template, hidden_set)
	return explosion_template ~= nil and hidden_set[explosion_template.name] == true
end

mod.api.with_suppressed_vfx = function(explosion_template, call_original)
	local saved_scalable_vfx = explosion_template.scalable_vfx
	local saved_vfx = explosion_template.vfx

	explosion_template.scalable_vfx = nil
	explosion_template.vfx = nil

	local ok, err = pcall(call_original)

	explosion_template.scalable_vfx = saved_scalable_vfx
	explosion_template.vfx = saved_vfx

	if not ok then
		error(err)
	end
end

local hidden = {}

local refresh = function()
	hidden = mod.api.build_hidden_set(SOURCES, {
		hide_rumbler  = mod:get("hide_rumbler"),
		hide_gauntlet = mod:get("hide_gauntlet"),
		hide_grenades = mod:get("hide_grenades"),
	})
end

mod.on_all_mods_loaded = function()
	mod:info(mod.version)

	refresh()

	local Explosion = require("scripts/utilities/attack/explosion")

	mod:hook(Explosion, "create_husk_explosion", function(func, world, physics_world, wwise_world, attacking_owner_unit_or_nil, explosion_template, position, rotation, radius_variables, charge_level)
		if mod.api.should_hide(explosion_template, hidden) then
			mod.api.with_suppressed_vfx(explosion_template, function()
				func(world, physics_world, wwise_world, attacking_owner_unit_or_nil, explosion_template, position, rotation, radius_variables, charge_level)
			end)

			return
		end

		return func(world, physics_world, wwise_world, attacking_owner_unit_or_nil, explosion_template, position, rotation, radius_variables, charge_level)
	end)
end

mod.on_setting_changed = function()
	refresh()
end
