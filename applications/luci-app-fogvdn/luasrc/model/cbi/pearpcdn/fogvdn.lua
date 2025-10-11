uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"
local json = require "luci.jsonc"
m = Map("fogvdn", translate("OpenFog Node"))
s = m:section(NamedSection, "main", "main", translate("Main"))
s.description = translate("Note: The OpenFog service must not be operated concurrently with peer services in the same category.")


act_status = s:option(DummyValue, "act_status", translate("Status"))
act_status.template = "pcdn/act_status"

enabled = s:option(Flag, "enable", translate("Enable"))
enabled.default = 0

local function get_installation_path()
    local path_file = "/etc/pear/pear_installation_path"
    local file, err = io.open(path_file, "r")
    if not file then 
        return "" 
    end
    
    local content = file:read("*a")
    file:close()
    
    local path = content:match("INSTALLATION_PATH=([^\r\n]*)")
    return path and path:gsub("%s+$", "") or ""
end

local installation_path = get_installation_path()

node_info_file = installation_path .. "/etc/pear/pear_monitor/node_info.json"
if fs.access(node_info_file) then
    local node_info = fs.readfile(node_info_file)
    node_info = json.parse(node_info)
    for k,v in pairs(node_info) do
        if k == "node_id" then
            option = s:option(DummyValue, "_"..k, translate("Node ID"))
            option.value = v
        end
    end
end

storage_info_file = installation_path .. "/etc/pear/pear_monitor/storage_info.json"
if fs.access(storage_info_file) then
    local storage_info = fs.readfile(storage_info_file)
    storage_info = json.parse(storage_info)
    for k,v in pairs(storage_info) do
        if k == "os_drive_serial" then
            option = s:option(DummyValue, "_"..k, translate("OS Drive Serial"))
            option.value = v
        end
    end
end

openfog_link=s:option(DummyValue, "openfog_link", translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"Openfogos.com\" onclick=\"window.open('https://openfogos.com/')\" />"))
openfog_link.description = translate("OpenFogOS Official Website")

local function get_tutorial_url()
    local openwrt_release = luci.sys.exec("cat /etc/openwrt_release | grep DISTRIB_DESCRIPTION | cut -d '=' -f 2")
    if openwrt_release and openwrt_release:match("QWRT") then
        return "https://openfogos.com/help/pearos_openwrt/router.md"
    elseif openwrt_release and openwrt_release:match("iStoreOS") then
        return "https://openfogos.com/help/plugin/istoreos.md"
    else
        return nil
    end
end

tutorial_url = get_tutorial_url()
if tutorial_url then
    tutorial_link=s:option(DummyValue, "tutorial_link", "<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"" .. translate("Tutorial") .. "\" onclick=\"window.open('" .. tutorial_url .. "')\" />")
    tutorial_link.description = translate("OpenFog Tutorial")
end



s = m:section(TypedSection, "instance", translate("Settings"))
s.anonymous = true
s.description = translate("OpenFog Settings")

username = s:option(Value, "username", translate("Username"))
username.description = translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"Register\" onclick=\"window.open('https://account.openfogos.com/signup?source%3Dopenfogos.com%26')\" />")

region = s:option(Value, "region", translate("Region"))
region.optional = true
region.template="cbi/city"


isp = s:option(Value, "isp", translate("ISP"))
isp.optional = true
isp:value("电信",  translate("China Telecom"))
isp:value("移动",  translate("China Mobile"))
isp:value("联通",  translate("China Unicom"))

local function get_cpu_arch()
    local handle = io.popen("uname -m")
    if not handle then
        return "unknown"
    end
    
    local arch = handle:read("*a")
    handle:close()
    
    if arch then
        arch = arch:gsub("%s+", "")
        return arch
    end
    
    return "unknown"
end

-- 根据CPU架构获取最小上传速度
local function get_min_upload_speed()
    local arch = get_cpu_arch()
    
    if arch == "x86_64" then
        return 30
    elseif arch == "aarch64" or arch:match("^armv7") then
        return 20
    else
        return 20
    end
end

local tmpl = translate("It is recommended to provide at least %dGB of storage space.")
per_line_up_bw = s:option(Value, "per_line_up_bw", translate("Upload Speed(Mbps)"))
per_line_up_bw.template = "cbi/digitonlyvalue"
per_line_up_bw.datatype = "uinteger"
-- 将模板放在 per_line_up_bw 的 description 中，初值为 0
per_line_up_bw.description = [[<span id="up_bw_hint_desc" data-template="]]
  .. luci.util.pcdata(tmpl) .. [[">]]
  .. luci.util.pcdata(tmpl:format(0)) .. [[</span>]]

-- 3) 渲染结束时注入脚本，定位 per_line_up_bw 的输入框与上面这个 span，实时更新
local _render = m.render
function m.render(self, ...)
  _render(self, ...)
  luci.http.write([[
  <script>
  (function(){
    // 定位 per_line_up_bw 的 input
    var input = document.querySelector('input[name="cbid.fogvdn.instance.per_line_up_bw"]');
    if (!input) {
      var candidates = document.querySelectorAll('input.cbi-input-text, input[type="text"], input[type="number"]');
      for (var i = 0; i < candidates.length; i++) {
        if (candidates[i].name && candidates[i].name.indexOf('cbid.fogvdn.') === 0 &&
            candidates[i].name.endsWith('.per_line_up_bw')) {
          input = candidates[i]; break;
        }
      }
    }

    var descSpan = document.getElementById('up_bw_hint_desc');
    if (!input || !descSpan) return;

    var template = descSpan.getAttribute('data-template') || '';
    function parseNum(v){ v = (''+(v??'')).trim(); if(!v) return NaN; var n=Number(v); return isNaN(n)?NaN:n; }
    function recommendG(n){ return 2*n; }

    function update(){
      var n = parseNum(input.value);
      var g = isNaN(n) ? 0 : recommendG(n);
      descSpan.textContent = template.replace('%d', String(g));
    }

    update();
    input.addEventListener('input', update);
    input.addEventListener('change', update);
  })();
  </script>
  ]])
end


-- 添加验证函数
function per_line_up_bw.validate(self, value, section)
    local min_upload_speed = get_min_upload_speed()
    
    if value and value ~= "" then
        local num_value = tonumber(value)
        if not num_value then
            per_line_up_bw.description = [[<b style="color: red">]] .. translate("ERROR: Invalid number format") .. "</b>"
            return nil
        end
        
        if num_value < min_upload_speed then
            local arch = get_cpu_arch()
            per_line_up_bw.description = [[<b style="color: red">]] .. translate("ERROR: Upload Speed must more than " .. min_upload_speed .. " Mbps") .. "</b>"
            return nil
        end
    end
    
    -- 如果验证通过，调用父类的验证方法
    return Value.validate(self, value, section)
end

per_line_down_bw = s:option(Value, "per_line_down_bw", translate("Download Speed(Mbps)"))
per_line_down_bw.template = "cbi/digitonlyvalue"
per_line_down_bw.datatype = "uinteger"

limited_memory = s:option(Value, "limited_memory", translate("Limited Memory(%)"))
limited_memory.optional = true
limited_memory.template = "cbi/digitonlyvalue"
limited_memory.datatype = "range(0, 100)"
-- 0-100%
limited_storage = s:option(Value, "limited_storage", translate("Limited Storage(%)"))
limited_storage.optional = true
limited_storage.template = "cbi/digitonlyvalue"
limited_storage.datatype = "range(0, 100)"
-- 0-100%

limited_area = s:option(Value, "limited_area", translate("Limited Area"))
limited_area.default = "2"
limited_area:value("-1", translate("Unset: If you are unsure about the operator's restrictions on inter-provincial traffic, it is recommended to choose this option."))
limited_area:value("0", translate("Domestic: Traffic will be scheduled nationwide, resulting in a higher proportion of inter-provincial traffic, which may lead to restrictions by the operator."))
limited_area:value("1", translate("Provincial: Traffic will only be scheduled within the province where it is located, which is a safer scheduling mode, but the volume of traffic may decrease."))
limited_area:value("2", translate("Regional: Traffic will only be scheduled within the region where it is located, resulting in a lower proportion of inter-provincial traffic. This mode provides a balanced approach between safety and traffic volume."))
-- 限制地区 -1 不设置（采用openfogos默认） 0 全国调度，1 省份调度，2 大区调度

nics = s:option(DynamicList,"nics", translate("Interfaces"))
nics.description = translate("Please utilize the network port with active internet connectivity.")
-- uci:foreach("multiwan","multiwan",function (instance)
--     nics:value(instance["tag"])
-- end
-- )
--list /sys/class/net, filter bridge device
cmd="/usr/share/pcdn/check_netdev get_netdevs"
json_dump=luci.sys.exec(cmd)
devs=json.parse(json_dump)
for k,v in pairs(devs) do
    nics:value(k,k.." ["..v.."]")
end

storage = s:option(DynamicList, "storage", translate("Storage"))
storage.description = translate("Please prioritize solid-state drives with integrated DRAM cache and write-through capability, preferably meeting enterprise-grade specifications.")
--filter start with /etc /usr /root /var /tmp /dev /proc /sys /overlay /rom and root
mount_point = {}
cmd="/usr/share/pcdn/check_mount_point mount_point"
json_dump=luci.sys.exec(cmd)
mount_point=json.parse(json_dump)
for k,v in pairs(mount_point) do
    storage:value(k,k.."("..v..")")
end

btn = s:option(Button, "_filter", " ")
btn.inputtitle = translate("Apply Optimal Storage Settings")
btn.description = translate("In order to avoid the barrel effect, Click Me to estimat the optimal setup.")
btn.inputstyle = "apply"

-- 获取表中元素的索引
table.indexOf = function(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then return i end
    end
    return -1
end

-- 拷贝表
table.copy = function(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

-- 解析并转换大小单位
function parseSize(size)
    if type(size) ~= "string" then return 0 end
    
    local unit = {"B", "K", "M", "G", "T"}
    
    local num, u = string.match(size, "^(%d+%.?%d*)([KMGT]?)$")
    if not num then return 0 end
    
    local i = table.indexOf(unit, u)
    
    -- 如果没有找到单位，默认为字节
    if i == -1 then
        return tonumber(num)
    else
        return tonumber(num) * (1024 ^ i)
    end
end

-- 获取最佳存储方案
function getOptimalSolution(numsObjArray)
    if type(numsObjArray) ~= "table" or #numsObjArray == 0 then return {} end
    
    -- 拷贝并按大小排序
    local nums = {}
    for _, v in ipairs(numsObjArray) do
        table.insert(nums, {name = v.name, size = v.size})
    end
    table.sort(nums, function(a, b)
        return parseSize(a.size) < parseSize(b.size)
    end)

    local max = 0
    local optimal = {}

    while #nums > 0 do
        local temp = parseSize(nums[1].size) * #nums
        if temp > max then
            max = temp
            optimal = table.copy(nums)
        end
        table.remove(nums, 1)  -- 移除第一个元素
    end

    -- 提取名称并排序
    local result = {}
    for _, v in ipairs(optimal) do
        table.insert(result, v.name)
    end
    table.sort(result)
    
    return result
end

function btn.write(self, section)
    local numsObjArray = {}

    for k,v in pairs(mount_point) do
        table.insert(numsObjArray, {name = k, size = v})
    end

    local optimalStorage = getOptimalSolution(numsObjArray)

    self.map:set(section, "storage", optimalStorage)
end

cmd="/usr/share/pcdn/check_mount_point unmounted_info"
json_dump=luci.sys.exec(cmd)

if json_dump ~= nil then
    local unmount_point = json.parse(json_dump)
    if unmount_point and unmount_point.unmounted_info and #unmount_point.unmounted_info ~= 0 then
        btn=s:option(DummyValue, "_toStorageManager", " ")
        btn.rawhtml = true
        btn.value = translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"Mount Page\" />")
        btn.href="/cgi-bin/luci/admin/services/storage_manager"
        btn.description = translate("Unmounted Storage:")

        local first = true
        for _,dev_info in ipairs(unmount_point.unmounted_info) do
            if first then
                btn.description = btn.description .. dev_info.path
                first = false
            else
                btn.description = btn.description .. "、" .. dev_info.path
            end
        end
    end
end

-------------
-- -- 1) 去掉单独的 up_bw_hint DummyValue 相关代码

-- -- 2) 在定义 per_line_up_bw 后，设置它自身的 description，并带 data-template
-- local tmpl = translate("It is recommended to use a hard disk of %dG or above.")
-- o_up = s:option(Value, "per_line_up_bw", translate("Upload Bandwidth"))  -- 你的原有定义
-- -- 将模板放在 per_line_up_bw 的 description 中，初值为 0
-- o_up.description = [[<span id="up_bw_hint_desc" data-template="]]
--   .. luci.util.pcdata(tmpl) .. [[">]]
--   .. luci.util.pcdata(tmpl:format(0)) .. [[</span>]]

-- -- 3) 渲染结束时注入脚本，定位 per_line_up_bw 的输入框与上面这个 span，实时更新
-- local _render = m.render
-- function m.render(self, ...)
--   _render(self, ...)
--   luci.http.write([[
--   <script>
--   (function(){
--     // 定位 per_line_up_bw 的 input
--     var input = document.querySelector('input[name="cbid.fogvdn.instance.per_line_up_bw"]');
--     if (!input) {
--       var candidates = document.querySelectorAll('input.cbi-input-text, input[type="text"], input[type="number"]');
--       for (var i = 0; i < candidates.length; i++) {
--         if (candidates[i].name && candidates[i].name.indexOf('cbid.fogvdn.') === 0 &&
--             candidates[i].name.endsWith('.per_line_up_bw')) {
--           input = candidates[i]; break;
--         }
--       }
--     }

--     var descSpan = document.getElementById('up_bw_hint_desc');
--     if (!input || !descSpan) return;

--     var template = descSpan.getAttribute('data-template') || '';
--     function parseNum(v){ v = (''+(v??'')).trim(); if(!v) return NaN; var n=Number(v); return isNaN(n)?NaN:n; }
--     function recommendG(n){ return 2*n; }

--     function update(){
--       var n = parseNum(input.value);
--       var g = isNaN(n) ? 0 : recommendG(n);
--       descSpan.textContent = template.replace('%d', String(g));
--     }

--     update();
--     input.addEventListener('input', update);
--     input.addEventListener('change', update);
--   })();
--   </script>
--   ]])
-- end

-------------

function m.on_after_commit(self)
    local uci = require "luci.model.uci".cursor()
    local enable = uci:get("fogvdn", "main", "enable")

    os.execute("echo " .. enable .. " > /tmp/fogvdn_enable_state")

    if enable == "1" then
        os.execute("/etc/init.d/fogvdn enable")
        os.execute("/etc/init.d/fogvdn start")
    end
end

return m
