require("lazy-set")
require("set")
require("map")
require("lazy").setup("plugins")

local TERMCS = os.getenv("TERMCS")

local background
if TERMCS == "light" then
    background = "light"
else
    background = "dark"
end

vim.o.background = background
