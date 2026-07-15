return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Clear Da Boom` encountered an error loading the Darktide Mod Framework.")

		new_mod("Clear Da Boom", {
			mod_script       = "Clear Da Boom/scripts/mods/Clear Da Boom/Clear Da Boom",
			mod_data         = "Clear Da Boom/scripts/mods/Clear Da Boom/Clear Da Boom_data",
			mod_localization = "Clear Da Boom/scripts/mods/Clear Da Boom/Clear Da Boom_localization",
		})
	end,
	packages = {},
}
