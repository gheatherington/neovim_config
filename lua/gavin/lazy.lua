local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "gavin.plugins" }, { import = "gavin.plugins.lsp" } }, {
	checker = {
		enabled = true,
		notify = false,
	},
	change_detection = {
		notify = false,
	},
	-- No installed plugin needs a rock: the six that ship a .rockspec all have
	-- a /lua dir, a simple build, and no non-Lua dependencies. Leaving rocks
	-- enabled only made :checkhealth lazy error about an unbuilt hererocks
	-- (private Lua 5.1 + luarocks) that nothing would ever use.
	rocks = {
		enabled = false,
	},
})
