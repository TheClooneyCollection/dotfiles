-- "kj" in insert mode acts like Escape
vim.keymap.set("i", "kj", "<Esc>", { noremap = true, silent = true })

-- Swap ; and : in Normal/Visual/Operator-pending modes
vim.keymap.set({ "n", "v", "o" }, ";", ":", { noremap = true })
vim.keymap.set({ "n", "v", "o" }, ":", ";", { noremap = true })

-- Command-line mode (when you type : commands)
vim.keymap.set("c", ";", ":", { noremap = true })
vim.keymap.set("c", ":", ";", { noremap = true })

-- Set leader to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- <leader>p paste from system clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { noremap = true, silent = true })
-- optional: <leader>P paste before cursor
vim.keymap.set({ "n", "v" }, "<leader>P", '"+P', { noremap = true, silent = true })
