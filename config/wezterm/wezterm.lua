local wezterm = require("wezterm")

local config = wezterm.config_builder()
local is_macos = wezterm.target_triple:find("apple") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Match Ghostty with WezTerm's bundled JetBrains Mono and Nerd Font symbols,
-- then fall back to a native monospace font for any remaining glyphs.
local font_fallback = { "JetBrains Mono", "Symbols Nerd Font Mono" }

if is_macos then
	table.insert(font_fallback, "Menlo")
elseif is_windows then
	table.insert(font_fallback, "Cascadia Mono")
else
	table.insert(font_fallback, "DejaVu Sans Mono")
end

config.font = wezterm.font_with_fallback(font_fallback)
config.font_size = 14
config.line_height = 1.1

config.color_scheme = "Catppuccin Macchiato"
config.colors = {
	cursor_fg = "#000000",
	tab_bar = {
		background = "#1e2030",
		active_tab = {
			bg_color = "#c6a0f6",
			fg_color = "#181926",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#24273a",
			fg_color = "#a5adce",
		},
		inactive_tab_hover = {
			bg_color = "#363a4f",
			fg_color = "#cad3f5",
			intensity = "Bold",
		},
		new_tab = {
			bg_color = "#1e2030",
			fg_color = "#c6a0f6",
		},
		new_tab_hover = {
			bg_color = "#363a4f",
			fg_color = "#a6da95",
			intensity = "Bold",
		},
	},
}
config.default_cursor_style = "BlinkingBlock"

if is_macos then
	-- Use WezTerm's integrated macOS title bar so its chrome follows the
	-- Catppuccin Macchiato base palette instead of the system window color.
	config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
	-- Keep the first terminal line below the macOS traffic-light controls.
	config.window_padding = { top = 32 }
	config.window_frame = {
		active_titlebar_bg = "#24273a",
		active_titlebar_fg = "#cad3f5",
		inactive_titlebar_bg = "#1e2030",
		inactive_titlebar_fg = "#a5adce",
	}
end

-- Ghostty fades inactive splits to 97% opacity. WezTerm's closest equivalent
-- is to preserve their color and reduce their brightness slightly.
config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 0.97,
}

-- Roughly the intended 800x600-pixel footprint from the Ghostty config.
-- Both terminals now express their declarative initial size in grid cells.
config.initial_cols = 96
config.initial_rows = 32

-- Keep a single terminal visually quiet; the tab bar appears when useful.
config.hide_tab_bar_if_only_one_tab = true

-- Give the PREMA server friendly persistent-mux and plain-SSH domain names.
-- Keeping remote_address as the SSH config host makes WezTerm reuse its
-- username, identity, host-key, and any future connection settings.
config.ssh_domains = wezterm.default_ssh_domains()

for _, domain in ipairs(config.ssh_domains) do
	if domain.name == "SSHMUX:10.100.0.136" then
		domain.name = "prema"
		domain.local_echo_threshold_ms = 10
	elseif domain.name == "SSH:10.100.0.136" then
		domain.name = "prema-ssh"
		domain.assume_shell = "Posix"
	end
end

if is_macos then
	-- Ghostty's `macos-option-as-alt = true` applies to both Option keys.
	config.send_composed_key_when_left_alt_is_pressed = false
	config.send_composed_key_when_right_alt_is_pressed = false
end

if is_windows then
	local wsl_domains = wezterm.default_wsl_domains()

	if #wsl_domains > 0 then
		-- Using a domain instead of invoking wsl.exe lets new panes and tabs
		-- follow the Linux cwd. Start in the first discovered distribution.
		for _, domain in ipairs(wsl_domains) do
			domain.default_cwd = "~"
		end

		config.wsl_domains = wsl_domains
		config.default_domain = wsl_domains[1].name
	else
		wezterm.log_warn("No WSL distribution found; using the Windows-local shell")
	end
end

local function is_shell(foreground_process_name)
	local shell_names = { "bash", "zsh", "fish", "sh", "ksh", "dash" }
	local process = string.match(foreground_process_name, "[^/\\]+$") or foreground_process_name

	for _, shell in ipairs(shell_names) do
		if process == shell then return true end
	end

	return false
end

wezterm.on("open-uri", function(_, pane, uri)
	local editor = "nvim"

	if uri:find("^file:") == 1 and not pane:is_alt_screen_active() then
		local url = wezterm.url.parse(uri)

		if is_shell(pane:get_foreground_process_name()) then
			local success, stdout, _ = wezterm.run_child_process({
				"file",
				"--brief",
				"--mime-type",
				url.file_path,
			})

			if success then
				if stdout:find("directory") then
					pane:send_text(wezterm.shell_join_args({ "cd", url.file_path }) .. "\r")
					pane:send_text(wezterm.shell_join_args({
						"ls",
						"-a",
						"-p",
						"--group-directories-first",
					}) .. "\r")
					return false
				end

				if stdout:find("text") then
					if url.fragment then
						pane:send_text(wezterm.shell_join_args({
							editor,
							"+" .. url.fragment,
							url.file_path,
						}) .. "\r")
					else
						pane:send_text(wezterm.shell_join_args({ editor, url.file_path }) .. "\r")
					end
					return false
				end
			end
		else
			local edit_cmd = url.fragment and editor .. ' +' .. url.fragment .. ' "$_f"'
				or editor .. ' "$_f"'
			local cmd = '_f="'
				.. url.file_path
				.. '"; { test -d "$_f" && { cd "$_f" ; ls -a -p --hyperlink --group-directories-first; }; } '
				.. '|| { test "$(file --brief --mime-type "$_f" | cut -d/ -f1 || true)" = "text" && '
				.. edit_cmd
				.. "; }; echo"
			pane:send_text(cmd .. "\r")
			return false
		end
	end
end)

return config
