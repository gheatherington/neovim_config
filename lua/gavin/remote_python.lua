-- Remote Python environments for files on sshfs mounts.
--
-- basedpyright runs locally and can't execute the remote interpreter (often a
-- different OS/arch), and crawling site-packages over FUSE would be slow and
-- usually outside the mount anyway. Instead, mirror the remote's
-- site/dist-packages into the cache once (.py/.pyi only; compiled .so modules
-- become empty placeholders so their imports still resolve), and install a
-- matching local interpreter with uv so the Python version agrees.

local M = {}

local SSH_OPTS = {
	"-o",
	"ControlPath=" .. vim.fn.expand("~/.ssh/sockets/%C"),
	"-o",
	"BatchMode=yes",
	"-o",
	"ConnectTimeout=5",
}

local syncing = {}

local function cache_dir(host)
	return vim.fs.joinpath(vim.fn.stdpath("cache"), "remote-python", host)
end

--- Active sshfs mount containing `path`, or nil.
function M.mount_for(path)
	if not path or path == "" then
		return nil
	end
	local ok, Config = pcall(require, "sshfs.config")
	if not ok then
		return nil
	end
	path = vim.fs.normalize(path)
	-- Skip shelling out to `mount` for every non-remote buffer
	if not vim.startswith(path, vim.fs.normalize(Config.get().mounts.base_dir) .. "/") then
		return nil
	end
	for _, mount in ipairs(require("sshfs.lib.mount_point").list_active()) do
		local mp = vim.fs.normalize(mount.mount_path)
		if path == mp or vim.startswith(path, mp .. "/") then
			return mount
		end
	end
end

--- Cached environment for `host`: { version, paths, python }, or nil if never synced.
function M.load(host)
	local f = io.open(vim.fs.joinpath(cache_dir(host), "env.json"))
	if not f then
		return nil
	end
	local ok, env = pcall(vim.json.decode, f:read("*a"))
	f:close()
	return ok and env or nil
end

--- Local mirror directories to use as basedpyright extraPaths.
function M.extra_paths(host, env)
	return vim.tbl_map(function(p)
		return vim.fs.joinpath(cache_dir(host), "root", p)
	end, env.paths)
end

-- Run a command from inside a coroutine and return its vim.system result.
local function run(cmd)
	local co = coroutine.running()
	vim.system(cmd, { text = true }, function(obj)
		vim.schedule(function()
			local ok, err = coroutine.resume(co, obj)
			if not ok then
				vim.notify("Remote Python sync error: " .. tostring(err), vim.log.levels.ERROR)
			end
		end)
	end)
	return coroutine.yield()
end

local function ssh(host, remote_cmd)
	return run(vim.list_extend(vim.list_extend({ "ssh" }, SSH_OPTS), { host, remote_cmd }))
end

--- Mirror `host`'s Python packages into the cache, then call on_done().
function M.sync(host, on_done)
	if syncing[host] then
		return
	end
	syncing[host] = true
	vim.notify("Syncing Python packages from " .. host .. " (one-time, may take a minute)...")

	coroutine.wrap(function()
		local function fail(msg)
			syncing[host] = nil
			vim.notify("Remote Python sync failed for " .. host .. ": " .. vim.trim(msg), vim.log.levels.ERROR)
		end

		local probe = "import sys, json; print(json.dumps({'version': '%d.%d' % sys.version_info[:2], "
			.. "'paths': [p for p in sys.path if p.endswith(('site-packages', 'dist-packages'))]}))"
		local res = ssh(host, "python3 -c " .. vim.fn.shellescape(probe))
		if res.code ~= 0 then
			return fail(res.stderr ~= "" and res.stderr or "could not run python3 on remote")
		end
		local ok, env = pcall(vim.json.decode, res.stdout)
		if not ok then
			return fail("unexpected probe output: " .. res.stdout)
		end

		-- Only directories that actually exist on the remote
		local quoted = table.concat(vim.tbl_map(vim.fn.shellescape, env.paths), " ")
		res = ssh(host, "for d in " .. quoted .. '; do [ -d "$d" ] && echo "$d"; done')
		env.paths = vim.split(vim.trim(res.stdout), "\n", { trimempty = true })

		local root = vim.fs.joinpath(cache_dir(host), "root")
		for _, p in ipairs(env.paths) do
			local dest = root .. p
			vim.fn.mkdir(dest, "p")
			res = run({
				"rsync",
				"-az",
				"--delete",
				"--prune-empty-dirs",
				"--include=*/",
				"--include=*.py",
				"--include=*.pyi",
				"--include=py.typed",
				"--exclude=*",
				"-e",
				"ssh " .. table.concat(SSH_OPTS, " "),
				host .. ":" .. p .. "/",
				dest .. "/",
			})
			if res.code ~= 0 then
				return fail("rsync " .. p .. ": " .. res.stderr)
			end
		end

		-- Compiled modules: empty placeholders are enough for import resolution
		quoted = table.concat(vim.tbl_map(vim.fn.shellescape, env.paths), " ")
		res = ssh(host, "find " .. quoted .. " -name '*.so' 2>/dev/null")
		for _, so in ipairs(vim.split(res.stdout, "\n", { trimempty = true })) do
			local local_so = root .. so
			if not vim.uv.fs_stat(local_so) then
				vim.fn.mkdir(vim.fs.dirname(local_so), "p")
				local f = io.open(local_so, "w")
				if f then
					f:close()
				end
			end
		end

		-- Matching local interpreter so basedpyright targets the remote's version
		if vim.fn.executable("uv") == 1 then
			run({ "uv", "python", "install", env.version })
			res = run({ "uv", "python", "find", "--managed-python", env.version })
			if res.code == 0 then
				env.python = vim.trim(res.stdout)
			end
		end

		local f = io.open(vim.fs.joinpath(cache_dir(host), "env.json"), "w")
		if not f then
			return fail("could not write env.json")
		end
		f:write(vim.json.encode(env))
		f:close()

		syncing[host] = nil
		vim.notify(string.format("Synced Python %s packages from %s", env.version, host))
		if on_done then
			on_done()
		end
	end)()
end

-- Built-in :lsp (0.12); errors only when no basedpyright client is running
local function restart_basedpyright()
	pcall(vim.cmd, "lsp restart basedpyright")
end

function M.setup()
	vim.api.nvim_create_user_command("RemotePySync", function(opts)
		local host = opts.args ~= "" and opts.args or nil
		if not host then
			local mount = M.mount_for(vim.api.nvim_buf_get_name(0)) or require("sshfs.lib.mount_point").get_active()
			host = mount and mount.host
		end
		if not host then
			vim.notify("Not on an sshfs mount; pass a host: :RemotePySync <host>", vim.log.levels.WARN)
			return
		end
		M.sync(host, restart_basedpyright)
	end, { nargs = "?", desc = "Mirror a remote host's Python packages for basedpyright" })
end

--- basedpyright root_dir: normal markers, but never above the sshfs mount root.
function M.root_dir(markers)
	return function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, markers)
		local mount = M.mount_for(vim.api.nvim_buf_get_name(bufnr))
		if mount and not (root and vim.startswith(root, mount.mount_path)) then
			root = mount.mount_path
		end
		on_dir(root)
	end
end

--- basedpyright before_init hook for mounted projects. Returns the interpreter
--- to use (or nil to keep the default); kicks off a sync if none is cached.
function M.apply(config)
	local mount = M.mount_for(config.root_dir)
	if not mount then
		return nil
	end
	local env = M.load(mount.host)
	if not env then
		M.sync(mount.host, restart_basedpyright)
		return nil
	end
	-- Mutate in place: the client already holds a reference to config.settings
	config.settings.basedpyright = vim.tbl_deep_extend("force", config.settings.basedpyright or {}, {
		analysis = { extraPaths = M.extra_paths(mount.host, env) },
	})
	return env.python
end

return M
