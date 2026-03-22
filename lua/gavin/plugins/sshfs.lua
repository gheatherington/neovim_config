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
        auto_change_to_dir = false,
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
      if jid <= 0 then return false end
      return vim.fn.jobwait({ jid }, 5000)[1] == 0
    end
    MountPoint.unmount = function(mount_path)
      local ok = try_cmd({ "umount", mount_path })
        or try_cmd({ "diskutil", "unmount", "force", mount_path })
      if ok then vim.fn.delete(mount_path, "d") end
      return ok
    end
  end,
}
