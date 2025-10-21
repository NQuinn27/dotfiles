return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local function get_lualine_theme()
            local colorscheme = vim.g.colors_name
            if colorscheme and colorscheme:match("catppuccin") then
                return "catppuccin"
            elseif colorscheme and colorscheme:match("solarized") then
                return "solarized"
            else
                return "auto"
            end
        end

        require("lualine").setup({
            options = {
                icons_enabled = true,
                component_separators = "|",
                section_separators = "",
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch" },

                lualine_c = {
                    { "diagnostics" },
                    {
                        "filetype",
                        icon_only = true,
                        separator = "",
                        padding = { left = 1, right = 0 },
                    },
                    { "filename" },
                },
                lualine_x = {
                    {
                        function()
                            return "  " .. require("dap").status()
                        end,
                        cond = function()
                            return package.loaded["dap"] and require("dap").status() ~= ""
                        end,
                        color = function()
                            return { fg = Snacks.util.color("Debug") }
                        end,
                    },
                    {
                        "diff",
                        source = function()
                            local gitsigns = vim.b.gitsigns_status_dict
                            if gitsigns then
                                return {
                                    added = gitsigns.added,
                                    modified = gitsigns.changed,
                                    removed = gitsigns.removed,
                                }
                            end
                        end,
                    },
                },
                lualine_y = {
                    { "progress", separator = " ",                  padding = { left = 1, right = 0 } },
                    { "location", padding = { left = 0, right = 1 } },
                },
                lualine_z = {
                    function()
                        return " " .. os.date("%R")
                    end,
                },
            },
        })

        -- Update lualine theme when colorscheme changes
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = function()
                require("lualine").setup({
                    options = {
                        theme = get_lualine_theme(),
                    },
                })
            end,
        })
    end,
}
