-- Offline unit tests for Clear Da Boom core logic. Run with LuaJIT.
-- Stubs DMF (get_mod) then loads the main script and drives mod.api directly.

local passed, failed = 0, 0
local function check(name, ok)
	if ok then passed = passed + 1
	else failed = failed + 1; print("FAIL: " .. name) end
end

-- Minimal DMF stub: get_mod returns a fake mod object.
local fake_mod = { api = {} }
function fake_mod:info(...) end
function fake_mod:warning(...) end
function fake_mod:localize(_) return "" end
_G.get_mod = function(_) return fake_mod end

-- Load the main script (top level only touches get_mod / mod.version / defines functions).
local here = arg[0]:gsub("[^/\\]+$", "")
dofile(here .. "../scripts/mods/Clear Da Boom/Clear Da Boom.lua")

local api = fake_mod.api
local SOURCES = fake_mod.SOURCES  -- exposed for the test

-- Build a fake ExplosionTemplates with two vfx-shapes + one missing name.
local function fresh_templates()
	local orig_scalable = { { min_radius = 5, effects = { "a" } } }
	local orig_vfx = { "b" }
	return {
		ogryn_thumper_grenade         = { scalable_vfx = orig_scalable, sfx = { "boom" } },
		ogryn_thumper_grenade_instant = { scalable_vfx = orig_scalable },
		default_gauntlet_grenade      = { scalable_vfx = orig_scalable },
		special_gauntlet_grenade      = { scalable_vfx = orig_scalable },
		ogryn_grenade_frag            = { scalable_vfx = orig_scalable },
		ogryn_box_cluster_frag        = { vfx = orig_vfx },  -- vfx-shape variant
	}
end

-- Test 1: build_cache captures originals and warns on missing.
do
	local t = fresh_templates()
	t.special_gauntlet_grenade = nil  -- simulate a patch renaming one template
	local warned = {}
	local cache = api.build_cache(t, SOURCES, function(n) warned[n] = true end)
	check("caches present scalable_vfx", cache.ogryn_thumper_grenade.scalable_vfx == t.ogryn_thumper_grenade.scalable_vfx)
	check("caches present vfx", cache.ogryn_box_cluster_frag.vfx == t.ogryn_box_cluster_frag.vfx)
	check("warns on missing", warned.special_gauntlet_grenade == true)
	check("no cache entry for missing", cache.special_gauntlet_grenade == nil)
end

-- Test 2: apply hide=true nils both vfx fields.
do
	local t = fresh_templates()
	local cache = api.build_cache(t, SOURCES, nil)
	api.apply(t, cache, SOURCES, { hide_rumbler = true, hide_gauntlet = true, hide_grenades = true })
	check("rumbler scalable_vfx nil", t.ogryn_thumper_grenade.scalable_vfx == nil)
	check("box vfx nil", t.ogryn_box_cluster_frag.vfx == nil)
	check("sfx untouched", t.ogryn_thumper_grenade.sfx[1] == "boom")
end

-- Test 3: apply hide=false restores the exact original references.
do
	local t = fresh_templates()
	local original_ref = t.ogryn_thumper_grenade.scalable_vfx
	local box_ref = t.ogryn_box_cluster_frag.vfx
	local cache = api.build_cache(t, SOURCES, nil)
	api.apply(t, cache, SOURCES, { hide_rumbler = true, hide_gauntlet = true, hide_grenades = true })
	api.apply(t, cache, SOURCES, { hide_rumbler = false, hide_gauntlet = false, hide_grenades = false })
	check("restores rumbler ref", t.ogryn_thumper_grenade.scalable_vfx == original_ref)
	check("restores box ref", t.ogryn_box_cluster_frag.vfx == box_ref)
end

-- Test 4: per-source independence — hiding only rumbler leaves gauntlet visible.
do
	local t = fresh_templates()
	local gauntlet_ref = t.default_gauntlet_grenade.scalable_vfx
	local cache = api.build_cache(t, SOURCES, nil)
	api.apply(t, cache, SOURCES, { hide_rumbler = true, hide_gauntlet = false, hide_grenades = false })
	check("rumbler hidden", t.ogryn_thumper_grenade.scalable_vfx == nil)
	check("gauntlet still shown", t.default_gauntlet_grenade.scalable_vfx == gauntlet_ref)
end

-- Test 5: missing template does not crash apply.
do
	local t = fresh_templates()
	local cache = api.build_cache(t, SOURCES, nil)
	t.ogryn_grenade_frag = nil
	local ok = pcall(api.apply, t, cache, SOURCES, { hide_rumbler = true, hide_gauntlet = true, hide_grenades = true })
	check("apply survives missing template", ok)
end

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
