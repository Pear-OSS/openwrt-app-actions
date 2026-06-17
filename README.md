# FogVDN OpenWrt 插件自动编译仓库

本仓库用于我司 FogVDN 产品的 OpenWrt 插件专属编译与打包。

当前 GitHub Actions 已固定为在代码变更后自动构建，仅编译以下两个包：

- fogvdn
- luci-app-fogvdn

其中：

- fogvdn 负责打包 FogVDN 二进制程序及相关运行文件
- luci-app-fogvdn 提供 OpenWrt LuCI 管理界面、配置文件和启动脚本

## 工作流说明

当前工作流定义见 [.github/workflows/main.yml](.github/workflows/main.yml)。

- 触发方式：push 到 main 分支时自动编译
- 校验方式：向 main 分支发起 pull request 时也会自动执行编译检查
- 编译范围：固定为 fogvdn 和 luci-app-fogvdn
- 目标架构：x64、arm64
- 使用 SDK：OpenWrt 21.02.3 SDK

当前默认上传的构建产物目录为：

- x86_64
- aarch64_cortex-a53

## 使用方式

### 1. 提交代码

在以下目录中修改 FogVDN 相关代码后，提交并推送到 GitHub：

- [applications/fogvdn](applications/fogvdn)
- [applications/luci-app-fogvdn](applications/luci-app-fogvdn)
- [feeds.conf](feeds.conf)
- [.github/workflows/main.yml](.github/workflows/main.yml)

### 2. 自动触发编译

推送到 main 分支后，GitHub Actions 会自动启动 Build IPKs 工作流，无需手动进入 Actions 页面执行 Run workflow。

如果是开发分支代码，也可以通过向 main 提交 Pull Request 的方式触发同一套编译检查。

### 3. 下载编译产物

编译完成后：

1. 打开 GitHub 仓库的 Actions 页面
2. 进入对应的 Build IPKs 任务
3. 在 Artifacts 区域下载对应架构的产物压缩包

产物中包含 fogvdn 和 luci-app-fogvdn 的 IPK 包，以及依照工作流保留下来的对应包目录内容。

## 仓库结构

- [applications/fogvdn](applications/fogvdn)：FogVDN 主程序包定义
- [applications/luci-app-fogvdn](applications/luci-app-fogvdn)：FogVDN 的 LuCI 管理插件
- [.github/workflows/main.yml](.github/workflows/main.yml)：GitHub Actions 自动编译入口
- [.github/workflows/x64.env](.github/workflows/x64.env)：x64 SDK 配置
- [.github/workflows/arm64.env](.github/workflows/arm64.env)：arm64 SDK 配置
- [feeds.conf](feeds.conf)：附加 feed 源配置
- [forkapp](forkapp)：仓库内置的辅助开发工具
- [tools/simple-install.sh](tools/simple-install.sh)：上传后在设备端执行的简单安装脚本

## 本地开发说明

工作流会把本仓库的 [applications](applications) 目录以 src-link 的方式加入 OpenWrt SDK feed，然后结合 [feeds.conf](feeds.conf) 中定义的外部 feed 完成依赖解析和编译。

如果修改了包定义、LuCI 页面、初始化脚本或依赖关系，直接提交后即可由 CI 进行统一构建验证。

## ForkApp 辅助工具

[forkapp](forkapp) 目录下提供辅助开发工具，可用于复制应用目录或将插件上传到测试设备。

示例：

```bash
cd forkapp
./build.sh
./forkapp forkapp -from ../applications/luci-app-fogvdn -to ../applications/luci-app-demo
./forkapp upload -ip 192.168.100.1 -pwd "password" -from ../applications/luci-app-demo -to /root/
./forkapp upload -ip 192.168.100.1 -pwd "password" -from ../applications/luci-app-demo -to /root/ -script ../tools/simple-install.sh -install
```

如无本地联调需求，可忽略该工具。
