-- Offline unit tests for Clear Da Boom core logic. Run with LuaJIT.
-- Stubs DMF (get_mod) then loads the main script and drives mod.api directly.
-- The hook + require live inside on_all_mods_loaded, which the test never calls,
-- so no game-only path is touched offline.

local passed, failed = 0, 0
local function check(name, ok)
	if ok then passed = passed + 1
	else failed = failed + 1; print("FAIL: " .. name) end
end

local fake_mod = { api = {} }
function fake_mod:info(...) end
function fake_mod:warning(...) end
function fake_mod:localize(_) return "" end
_G.get_mod = function(_) return fake_mod end

local here = arg[0]:gsub("[^/\\]+$", "")
dofile(here .. "../scripts/mods/Clear Da Boom/Clear Da Boom.lua")

local api = fake_mod.api
local SOURCES = fake_mod.SOURCES

-- build_hidden_set --------------------------------------------------
do
	local all_on = api.build_hidden_set(SOURCES, { hide_rumbler = true, hide_gauntlet = true, hide_grenades = true })
	check("all-on hides all six", all_on.ogryn_thumper_grenade and all_on.ogryn_thumper_grenade_instant
		and all_on.default_gauntlet_grenade and all_on.special_gauntlet_grenade
		and all_on.ogryn_grenade_frag and all_on.ogryn_box_cluster_frag and true or false)

	local only_g = api.build_hidden_set(SOURCES, { hide_rumbler = false, hide_gauntlet = true, hide_grenades = false })
	check("only gauntlet hidden", only_g.default_gauntlet_grenade == true and only_g.special_gauntlet_grenade == true)
	check("rumbler not hidden when off", only_g.ogryn_thumper_grenade == nil)
	check("grenades not hidden when off", only_g.ogryn_grenade_frag == nil)

	local all_off = api.build_hidden_set(SOURCES, { hide_rumbler = false, hide_gauntlet = false, hide_grenades = false })
	check("all-off hides nothing", next(all_off) == nil)
end

-- should_hide -------------------------------------------------------
do
	local hidden = api.build_hidden_set(SOURCES, { hide_rumbler = true, hide_gauntlet = true, hide_grenades = true })
	check("should_hide true for targeted", api.should_hide({ name = "default_gauntlet_grenade" }, hidden) == true)
	check("should_hide false for non-targeted", api.should_hide({ name = "frag_grenade" }, hidden) == false)
	check("should_hide false for nil template", api.should_hide(nil, hidden) == false)

	local none = api.build_hidden_set(SOURCES, { hide_rumbler = false, hide_gauntlet = false, hide_grenades = false })
	check("should_hide false when setting off", api.should_hide({ name = "default_gauntlet_grenade" }, none) == false)
end

-- with_suppressed_vfx: scalable_vfx shape --------------------------
do
	local orig_scalable = { { min_radius = 2.5, effects = { "gg_boom" } } }
	local tmpl = { name = "default_gauntlet_grenade", scalable_vfx = orig_scalable, sfx = { "boom" } }
	local seen_scalable, seen_vfx, seen_sfx
	api.with_suppressed_vfx(tmpl, function()
		seen_scalable = tmpl.scalable_vfx
		seen_vfx = tmpl.vfx
		seen_sfx = tmpl.sfx
	end)
	check("scalable_vfx nil during original call", seen_scalable == nil)
	check("vfx nil during original call", seen_vfx == nil)
	check("sfx visible during original call", seen_sfx ~= nil and seen_sfx[1] == "boom")
	check("scalable_vfx restored to same ref after", tmpl.scalable_vfx == orig_scalable)
	check("sfx untouched after", tmpl.sfx[1] == "boom")
end

-- with_suppressed_vfx: vfx shape -----------------------------------
do
	local orig_vfx = { "box_boom" }
	local tmpl = { name = "ogryn_box_cluster_frag", vfx = orig_vfx }
	local seen_vfx = "sentinel"
	api.with_suppressed_vfx(tmpl, function() seen_vfx = tmpl.vfx end)
	check("vfx nil during original call", seen_vfx == nil)
	check("vfx restored to same ref after", tmpl.vfx == orig_vfx)
end

-- with_suppressed_vfx: restores even if the original errors ---------
do
	local orig_scalable = { { effects = { "x" } } }
	local tmpl = { name = "special_gauntlet_grenade", scalable_vfx = orig_scalable }
	local ok = pcall(api.with_suppressed_vfx, tmpl, function() error("boom in original") end)
	check("error is propagated", ok == false)
	check("scalable_vfx restored after error", tmpl.scalable_vfx == orig_scalable)
end

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
