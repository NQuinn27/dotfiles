vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")

local state = {
    floating = {
        buf = -1,
        win = -1
    }
}
-- Function to create a centered floating window
local function create_float(opts)
    opts = opts or {}

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate default size (80% of screen)
    local win_height = math.ceil(height * 0.8)
    local win_width = math.ceil(width * 0.8)

    -- Use provided dimensions if available
    win_height = opts.height or win_height
    win_width = opts.width or win_width

    -- Calculate starting position for centering
    local row = math.ceil((height - win_height) / 2)
    local col = math.ceil((width - win_width) / 2)

    -- Window options
    local win_opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded"
    }

    -- Create buffer
    local buf = nil
    if vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    -- Create window
    local win = vim.api.nvim_open_win(buf, true, win_opts)

    return { buf = buf, win = win }
end

-- Example usage:
-- Create default sized window (80%)
-- M.create_float()
--
-- Create custom sized window
-- M.create_float({ width = 100, height = 30 })

local toggle_terminal = function()
    if not vim.api.nvim_win_is_valid(state.floating.win) then
        state.floating = create_float { buf = state.floating.buf }
        if vim.bo[state.floating.buf].buftype ~= "terminal" then
            vim.cmd.terminal()
        end
    else
        vim.api.nvim_win_hide(state.floating.win)
    end
end

vim.api.nvim_create_user_command("Floaterminal", toggle_terminal , {})
vim.keymap.set({ "n", "t"}, "<leader>tt", toggle_terminal)
