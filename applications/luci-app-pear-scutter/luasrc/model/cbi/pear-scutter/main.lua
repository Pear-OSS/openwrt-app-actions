local m, s, o

m = Map("pear-scutter", translate("PearScutter"), translate("Configure execution plans. Save & Apply to reload service."))

-- 全局设置（可选）
s = m:section(NamedSection, "config", "global", translate("Global"))
s.addremove = true
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable"))
o.default = "0"

-- plan 列表
local p = m:section(TypedSection, "plan", translate("Plans"))
p.addremove = true
p.anonymous = true
p.template = "cbi/tsection"

-- 带基础校验的字段
local function int_option(section, key, title, placeholder, minv, maxv)
    local x = p:option(Value, key, title)
    x.datatype = "uinteger"
    if minv and maxv then
        x.datatype = "range(" .. minv .. "," .. maxv .. ")"
    end
    if placeholder then x.placeholder = placeholder end
    x.default = "0"
    return x
end

int_option(p, "bw_limit", translate("Bandwidth limit (Mbps)"), "0")
int_option(p, "max_download_size", translate("Max download size (GB)"), "0")
int_option(p, "threads", translate("Threads"), "0")

nic = s:option(Value,"nics", translate("Interfaces"))
cmd="/usr/share/pear-scutter/check_netdev get_netdevs"
json_dump=luci.sys.exec(cmd)
devs=json.parse(json_dump)
for k,v in pairs(devs) do
    nic:value(k,k.." ["..v.."]")
end

-- 自定义时间段控件（显示为 HH:MM -- HH:MM）
local timeRange = p:option(Value, "_time_range", translate("Active time range (HH:MM -- HH:MM)"))
timeRange.rmempty = false
timeRange.placeholder = "08:00 -- 23:30"
timeRange.template = "pear-scutter/timerange"   -- 指向我们自定义的视图模板

-- 将四个字段的值组装为回显文本
function timeRange.cfgvalue(self, section)
    local sh = tonumber(m.uci:get("pear-scutter", section, "start_time_hour")) or 0
    local sm = tonumber(m.uci:get("pear-scutter", section, "start_time_minute")) or 0
    local eh = tonumber(m.uci:get("pear-scutter", section, "end_time_hour")) or 0
    local em = tonumber(m.uci:get("pear-scutter", section, "end_time_minute")) or 0
    local function z2(x) x = tonumber(x) or 0; return (x < 10) and ("0" .. x) or tostring(x) end
    return string.format("%s:%s -- %s:%s", z2(sh), z2(sm), z2(eh), z2(em))
end

-- 接收用户输入并拆回四个字段
function timeRange.write(self, section, value)
    -- 允许 "HH:MM -- HH:MM" 或 "HH:MM--HH:MM" 的空格差异
    value = tostring(value or "")
    local sh, sm, eh, em = value:match("^(%d%d?):(%d%d?)%s*%-%-%s*(%d%d?):(%d%d?)$")
    if not sh then
        -- 尝试去空格
        value = value:gsub("%s+", "")
        sh, sm, eh, em = value:match("^(%d%d?):(%d%d?)%-%-(%d%d?):(%d%d?)$")
    end
    sh, sm, eh, em = tonumber(sh), tonumber(sm), tonumber(eh), tonumber(em)

    -- 基本校验与剪裁
    local function clamp(v, lo, hi) v = tonumber(v) or 0; if v < lo then v = lo end; if v > hi then v = hi end; return v end
    sh = clamp(sh, 0, 23); sm = clamp(sm, 0, 59); eh = clamp(eh, 0, 23); em = clamp(em, 0, 59)

    -- 如果解析失败，用 0 填
    if not (sh and sm and eh and em) then
        sh, sm, eh, em = 0, 0, 0, 0
    end

    m.uci:set("pear-scutter", section, "start_time_hour", sh)
    m.uci:set("pear-scutter", section, "start_time_minute", sm)
    m.uci:set("pear-scutter", section, "end_time_hour", eh)
    m.uci:set("pear-scutter", section, "end_time_minute", em)
end

return m
