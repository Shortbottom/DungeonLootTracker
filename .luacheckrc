std = "lua51"
max_line_length = false
exclude_files = {
	"babelfish.lua",
	".luacheckrc",
	".github/*",
	".vscode*/*",
	".backups",
	"Libs"
}
ignore = {
	"11./SLASH_.*" -- Setting an undefined (Slash handler) global variable
}
globals = {
	"_G",
	"bit",
	"Constants",
	-- Blizzard Provided
	"InterfaceOptionsFrame_OpenToCategory",
	"InterfaceAddOnsList_Update",
	"InterfaceOptionsFrameAddOns",
	"OptionsListButtonToggle_OnClick",
	"C_AddOns",
	"Settings",
	"GetBuildInfo",
	-- misc custom
	"LibStub"
	-- FrameXML misc
}
