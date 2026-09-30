return {
	"uhs-robert/sshfs.nvim",
	lazy = false,
	opts = {
		connections = {
			ssh_configs = { "~/.ssh/config", "/etc/ssh/ssh_config" },
			sshfs_options = {
				reconnect = true,
				ConnectTimeout = 5,
				compression = "yes",
				ServerAliveInterval = 15,
				ServerAliveCountMax = 3,
				-- Disable broken plugin defaults (invalid on macOS sshfs 2.10):
				dir_cache = false,
				dcache_timeout = false,
				dcache_max_size = false,
				-- Correct cache option names:
				cache = "yes",
				cache_timeout = 20,
				cache_max_size = 10000,
			},
			control_persist = "10m",
			socket_dir = vim.fn.expand("$HOME/.ssh/sockets"),
		},
		mounts = {
			base_dir = vim.fn.expand("$HOME") .. "/mnt",
		},
		hooks = {
			on_exit = {
				auto_unmount = true,
				clean_mount_folders = true,
			},
			on_mount = {
				auto_change_to_dir = true,
				auto_run = "find",
			},
		},
		ui = {
			local_picker = {
				preferred_picker = "fzf-lua",
				fallback_to_netrw = true,
			},
			remote_picker = {
				preferred_picker = "fzf-lua",
			},
		},
		lead_prefix = "<leader>m",
	},
	config = function(_, opts)
		require("sshfs").setup(opts)
		-- Override unmount: plugin's default sequence ends with `diskutil unmount` (no force),
		-- which macOS refuses for macFUSE mounts. Replace with graceful → force fallback.
		local MountPoint = require("sshfs.lib.mount_point")
		local function try_cmd(args)
			local jid = vim.fn.jobstart(args, { stdout_buffered = true, stderr_buffered = true })
			if jid <= 0 then
				return false
			end
			return vim.fn.jobwait({ jid }, 5000)[1] == 0
		end
		MountPoint.unmount = function(mount_path)
			local ok = try_cmd({ "umount", mount_path }) or try_cmd({ "diskutil", "unmount", "force", mount_path })
			if ok then
				vim.fn.delete(mount_path, "d")
			end
			return ok
		end

		-- Override mount: on macOS 27 + macFUSE 5, sshfs can't daemonize ("forking after
		-- mount is not supported"), so it stays in the foreground and the plugin — which
		-- waits for sshfs to exit — never reports until the mount dies (libfuse/sshfs#388).
		-- Run `sshfs -f` in the background instead and exit once the mount point is live.
		local Sshfs = require("sshfs.lib.sshfs")
		local build_mount_command = Sshfs.build_mount_command
		local wait_for_mount = [[
mnt=$1; shift
log=$(mktemp -t sshfs-nvim)
sshfs -f "$@" >"$log" 2>&1 </dev/null &
pid=$!
i=0
while [ $i -lt 60 ]; do
  if [ "$(stat -f %d "$mnt" 2>/dev/null)" != "$(stat -f %d "$(dirname "$mnt")")" ]; then
    rm -f "$log"; exit 0
  fi
  if ! kill -0 $pid 2>/dev/null; then
    grep -v 'forking a threaded process' "$log" >&2; rm -f "$log"; exit 1
  fi
  sleep 0.25; i=$((i + 1))
done
kill $pid 2>/dev/null
echo "timed out after 15s waiting for mount" >&2
grep -v 'forking a threaded process' "$log" >&2; rm -f "$log"; exit 1
]]
		Sshfs.build_mount_command = function(host, mount_point, remote_path_suffix)
			local cmd = build_mount_command(host, mount_point, remote_path_suffix)
			table.remove(cmd, 1) -- drop "sshfs"; the script re-adds it with -f
			return vim.list_extend({ "sh", "-c", wait_for_mount, "sshfs-fg", mount_point }, cmd)
		end

		-- Save a copy of the current buffer to a local path (prompted). The default
		-- destination remembers the last directory used this session.
		local last_dest_dir = vim.fn.expand("~/Downloads/")
		vim.keymap.set("n", "<leader>ms", function()
			local src = vim.api.nvim_buf_get_name(0)
			if src == "" then
				vim.notify("Buffer has no file name", vim.log.levels.WARN)
				return
			end
			local name = vim.fn.fnamemodify(src, ":t")
			vim.ui.input(
				{ prompt = "Copy buffer to: ", default = last_dest_dir .. name, completion = "file" },
				function(dest)
					if not dest or dest == "" then
						return
					end
					dest = vim.fn.fnamemodify(vim.fn.expand(dest), ":p")
					-- Trailing slash or existing directory: keep the original file name
					if dest:sub(-1) == "/" or vim.fn.isdirectory(dest) == 1 then
						dest = dest:match("^(.-)/*$") .. "/"
						dest = dest .. name
					end
					if vim.uv.fs_stat(dest) and vim.fn.confirm("Overwrite " .. dest .. "?", "&Yes\n&No", 2) ~= 1 then
						return
					end
					vim.fn.mkdir(vim.fn.fnamemodify(dest, ":h"), "p")
					-- noautocmd: skip format-on-save so the copy matches the buffer and
					-- the remote buffer itself is left untouched.
					local ok, err = pcall(vim.cmd, "noautocmd keepalt silent write! " .. vim.fn.fnameescape(dest))
					if not ok then
						vim.notify("Copy failed: " .. err, vim.log.levels.ERROR)
						return
					end
					last_dest_dir = vim.fn.fnamemodify(dest, ":h") .. "/"
					vim.notify("Copied to " .. dest)
				end
			)
		end, { desc = "Save copy of buffer to local path" })
	end,
}
