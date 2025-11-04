module("luci.controller.pear-scutter", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/pear-scutter") then
        return
    end
    entry({"admin", "services", "pear-scutter"}, alias("admin", "services", "pear-scutter", "config"), _("pear-scutter"), 50).dependent = true
    entry({"admin", "services", "pear-scutter", "config"}, cbi("pear-scutter/main"), _("Configuration"), 1).leaf = true
    -- 提供一个动作用于“立即重载/重启”
    entry({"admin", "services", "pear-scutter", "reload"}, call("action_reload"), _("Reload"), 2).leaf = true
end

function action_reload()
    luci.http.prepare_content("application/json")
    -- 触发服务 reload（会在 init 脚本中渲染 JSON 并热重载/重启）
    luci.sys.call("/etc/init.d/pear-scutter reload >/dev/null 2>&1")
    luci.http.write_json({ status = "ok" })
end
