local Config = require("lazy.core.config")
local Runner = require("lazy.manage.runner")
local Plugin = require("lazy.core.plugin")

local M = {}

---@class ManagerOpts
---@field wait? boolean
---@field clear? boolean
---@field interactive? boolean

---@param ropts RunnerOpts
---@param opts? ManagerOpts
function M.run(ropts, opts)
  opts = opts or {}
  if opts.interactive == nil then
    opts.interactive = Config.options.interactive
  end
  if ropts.interactive == nil then
    ropts.interactive = opts.interactive
  end

  if opts.clear then
    M.clear()
  end

  if opts.interactive then
    require("lazy.view").show()
  end

  ---@type Runner
  local runner = Runner.new(ropts)
  runner:start()

  vim.cmd([[do User LazyRender]])

  -- wait for post-install to finish
  runner:wait(function()
    vim.cmd([[do User LazyRender]])
  end)

  if opts.wait then
    runner:wait()
  end
end

---@param opts? ManagerOpts
function M.install(opts)
  M.run({
    pipeline = { "git.install", { "plugin.docs", "plugin.run" } },
    plugins = function(plugin)
      return plugin.uri and not plugin.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.update(opts)
  M.run({
    pipeline = { "git.update", { "plugin.docs", "plugin.run" }, "git.log" },
    plugins = function(plugin)
      return plugin.uri and plugin.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.log(opts)
  M.run({
    pipeline = { "git.log" },
    plugins = function(plugin)
      return plugin.uri and plugin.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.clean(opts)
  Plugin.update_state(true)
  M.run({
    pipeline = { "plugin.clean" },
    plugins = Config.to_clean,
  }, opts)
end

function M.clear()
  for _, plugin in pairs(Config.plugins) do
    -- clear updated status
    plugin.updated = nil
    -- clear finished tasks
    if plugin.tasks then
      ---@param task LazyTask
      plugin.tasks = vim.tbl_filter(function(task)
        return task:is_running()
      end, plugin.tasks)
    end
  end
  vim.cmd([[do User LazyRender]])
end

return M
