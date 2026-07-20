local uv = vim.uv or vim.loop

local uname = uv.os_uname()
local sysname = uname.sysname or ""
local release = (uname.release or ""):lower()

local M = {}

function M.is_macos()
	return sysname == "Darwin"
end

function M.is_linux()
	return sysname == "Linux"
end

function M.is_wsl()
	return M.is_linux() and release:find("microsoft", 1, true) ~= nil
end

function M.executable(cmd)
	return vim.fn.executable(cmd) == 1
end

function M.first_executable(candidates)
	for _, candidate in ipairs(candidates) do
		if M.executable(candidate) then
			return candidate
		end
	end
end

function M.readable(path)
	return uv.fs_stat(vim.fn.expand(path)) ~= nil
end

function M.codelldb_paths()
	local extension = M.is_macos() and ".dylib" or ".so"
	local root = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
	return {
		adapter = root .. "/adapter/codelldb",
		liblldb = root .. "/lldb/lib/liblldb" .. extension,
	}
end

return M
