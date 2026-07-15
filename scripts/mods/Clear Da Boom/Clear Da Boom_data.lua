local mod = get_mod("Clear Da Boom")

return {
	name = "Clear Da Boom",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id    = "hide_rumbler",
				type          = "checkbox",
				default_value = true,
			},
			{
				setting_id    = "hide_gauntlet",
				type          = "checkbox",
				default_value = true,
			},
			{
				setting_id    = "hide_grenades",
				type          = "checkbox",
				default_value = true,
			},
		},
	},
}
