# OpenWrt 软件包：libnfc-nci

用于 NXP PN7160 NFC 控制器 NCI 协议栈的 OpenWrt 软件包。

## 🔍 PN7160 的特殊性

### 为什么 i2cdetect 扫描不到？

根据 NXP 官方文档的说明，PN7160 不会响应标准的 I2C 扫描。原因如下：

**PN7160 的特殊特性：**
- 使用专有的 NCI (NFC Controller Interface) 协议
- 不是标准的 I2C 从设备
- 只响应特定的 NCI 命令序列
- 不响应普通的 I2C 读取操作
- 需要特定的初始化握手过程

**正确的使用方式：**
- 必须发送正确的 NCI 初始化命令
- 使用 NXP 提供的库和驱动
- 类似芯片（如 PN532、PN7150）也有相同特性
- 都需要专门的驱动程序

### 🛠️ 使用 NXP 官方驱动和库（推荐方法）

```bash
# 1. 获取 NXP 的 NCI 协议栈
git clone https://github.com/NXPNFCLinux/linux_libnfc-nci.git

# 2. 编译和安装
cd linux_libnfc-nci
./bootstrap
./configure
make
sudo make install

# 3. 配置设备树或内核驱动
# 需要在 Linux 内核中启用 PN7160 支持
```

---

## 📦 软件包结构

```
libnfc-nci/
├── Makefile              # OpenWrt 软件包定义
├── README.md             # 英文说明文档
├── README_CN.md          # 中文说明文档（本文件）
├── patches/              # 源代码补丁
│   ├── 001-change-config-dir.patch
│   ├── 002-fix-transport-config-path.patch
│   ├── 003-fix-config-path-provider.patch
│   └── 100-64bit-support.patch
├── files/                # 需要安装的额外文件
└── src/                  # （保留用于本地源码，如需要）
```

---

## 🔧 补丁说明

### 配置路径补丁 (001-003)

这些补丁将配置文件位置从 `/usr/local/etc/` 更改为 `/etc/nfc/`：

| 补丁文件 | 说明 |
|---------|------|
| **001-change-config-dir.patch** | 更新 `Makefile.am` 以将配置文件安装到 `/etc/nfc/` |
| **002-fix-transport-config-path.patch** | 更新 `config.cc` 中的传输路径 |
| **003-fix-config-path-provider.patch** | 更新 `ConfigPathProvider.cc` 中的所有配置路径 |

### 64位支持补丁 (100)

**100-64bit-support.patch**: 64位架构兼容性修复
- 类型转换修复（`unsigned int` 与 `size_t`）
- 指针解引用修复
- 数据结构对齐修复

---

## ⚙️ 配置文件

## ⚙️ 配置文件

软件包将配置文件安装到 `/etc/nfc/`：

**主要配置文件：**
- `libnfc-nci.conf` - 系统配置
- `libnfc-nxp.conf` - 供应商配置

**额外配置文件**（如果存在）：
- `libese-nxp.conf` - ESE 配置
- `libnfc-nxp_RF.conf` - RF 配置
- `libnfc-nxpTransit.conf` - Transit 配置

---

## 📦 构建的软件包

此软件包会生成三个软件包：

### 1. libnfc-nci - 主库
- `/usr/lib/libnfc_nci_linux.so*`
- `/etc/nfc/libnfc-nci.conf`
- `/etc/nfc/libnfc-nxp.conf`

### 2. libnfc-nci-utils - 实用工具
- `/usr/sbin/nfcDemoApp`

### 3. libpn7160-fw - 固件库
- `/usr/lib/libpn7160_fw.so*`

---

## 📋 依赖项

## 📋 依赖项

### 运行时依赖
| 依赖库 | 说明 |
|--------|------|
| `libstdcpp` | C++ 标准库 |
| `libpthread` | POSIX 线程库 |
| `librt` | 实时扩展库 |
| `libgpiod` | GPIO 库（用于 PN7160 硬件控制） |

### 编译依赖
- `autoconf`
- `automake`
- `libtool`

---

## 🚀 安装

### 1. 添加到 OpenWrt 构建系统

将此目录复制到您的 OpenWrt 软件包源：

```bash
# 用于 feeds/packages
cp -r libnfc-nci $(OPENWRT_DIR)/feeds/packages/libs/

# 或用于自定义软件包
cp -r libnfc-nci $(OPENWRT_DIR)/package/
```

### 2. 更新源（如果使用 feeds）

```bash
cd $(OPENWRT_DIR)
./scripts/feeds update -a
./scripts/feeds install -a
```

### 3. 配置软件包

```bash
make menuconfig
```

导航到：
- `Libraries` → 选择 `libnfc-nci`
- `Utilities` → 选择 `libnfc-nci-utils`
- `Libraries` → 选择 `libpn7160-fw`

### 4. 编译软件包

```bash
# 编译单个软件包
make package/libnfc-nci/compile V=s

# 清理并编译
make package/libnfc-nci/{clean,compile} V=s

# 编译所有选定的软件包
make -j$(nproc)
```

### 5. 查找编译好的软件包

```bash
ls $(OPENWRT_DIR)/bin/packages/*/packages/libnfc-nci*.ipk
```

---

## 🔌 硬件设置

### PN7160 到 OpenWrt 设备的连接

| 设备引脚 | PN7160 引脚 | 功能 |
|----------|-------------|------|
| 3.3V     | VDD         | 电源 |
| 5V       | VBAT        | 电源 |
| GND      | GND         | 地线 |
| I2C SDA  | SDA         | I2C 数据 |
| I2C SCL  | SCL         | I2C 时钟 |
| GPIO     | IRQ         | 中断 |
| GPIO     | VEN         | 使能 |
| GPIO     | DWL_REQ     | 下载 |

### 启用 I2C 接口

添加到 `/etc/config/modules` 或手动加载：
```bash
insmod i2c-dev
```

---

## 💻 使用方法

### 基本 NFC 操作

```bash
# 运行演示应用程序
nfcDemoApp poll

# 检查配置
cat /etc/nfc/libnfc-nci.conf
cat /etc/nfc/libnfc-nxp.conf
```

### 覆盖配置

您可以使用环境变量覆盖配置路径：
```bash
export LIBNFC_NCI_CONF_PATH=/custom/path/
```

---

## ⚠️ 重要注意事项

### 1. I2C 检测
PN7160 不会响应标准 I2C 扫描（`i2cdetect -y 1`）。这是正常行为，因为设备需要先进行 GPIO 初始化。

### 2. GPIO 库
确保安装了 `libgpiod`。现代内核（6.6+）需要此库。

### 3. 权限要求
应用程序需要访问：
- I2C 设备（`/dev/i2c-*`）
- GPIO 设备
- `/etc/nfc/` 中的配置文件

### 4. 内核要求
- **内核 < 6.6**: 使用传统 GPIO sysfs 接口
- **内核 >= 6.6**: 需要 libgpiod

---

## 🛠️ 故障排除

## 🛠️ 故障排除

### ❌ 问题："nfcservice init fail"

**解决方案：**
- ✓ 验证 GPIO 引脚配置正确
- ✓ 确保已安装 `libgpiod`
- ✓ 检查 I2C 接口是否已启用
- ✓ 验证硬件连接
- ✓ 检查 dmesg 查看内核消息

### ❌ 问题：找不到配置文件

**解决方案：**
- ✓ 验证文件存在于 `/etc/nfc/`
- ✓ 检查文件权限
- ✓ 查看应用程序日志以获取路径详细信息

### ❌ 问题：编译失败

**解决方案：**
- ✓ 确保在 menuconfig 中选择了所有依赖项
- ✓ 清理构建：`make package/libnfc-nci/clean`
- ✓ 检查构建日志：`make package/libnfc-nci/compile V=s`

---

## 👨‍💻 开发

### 添加自定义补丁

1. 在 `patches/` 目录中创建补丁文件
2. 命名格式：`NNN-描述.patch`
   - `000-099` → 配置补丁
   - `100-199` → 架构/平台补丁
   - `200-299` → 功能补丁
   - `900-999` → 本地/临时补丁
3. 补丁按数字顺序应用

### 测试更改

```bash
# 清理并重新编译
make package/libnfc-nci/clean
make package/libnfc-nci/compile V=s

# 在设备上测试
scp bin/packages/*/packages/libnfc-nci*.ipk root@device:/tmp/
ssh root@device "opkg install /tmp/libnfc-nci*.ipk"
```

---

## 📄 许可证

Apache License 2.0（详见源码中的 LICENSE.txt）

---

## 📚 参考资料

### 官方文档
- 🔗 [NXP 官方仓库](https://github.com/NXPNFCLinux/linux_libnfc-nci)
- 🔗 [NXP 社区移植指南 - Raspberry Pi 5](https://community.nxp.com/t5/NFC-Knowledge-Base/Porting-PN7160-NCI2-stack-to-Raspberry-Pi-5-OS-Bookworm/ta-p/1977521)
- 🔗 [PN7160 Linux 移植指南 (AN13287)](https://www.nxp.com/docs/en/application-note/AN13287.pdf)
- 🔗 [PN7160 评估套件快速入门指南 (AN12991)](https://www.nxp.com/docs/en/application-note/AN12991.pdf)

### 社区资源
- 🔗 [OM27160 Raspberry I2C 故障排除](https://community.nxp.com/t5/NFC/OM27160-raspberry-i2c-NfcService-Init-Failed/m-p/1825250/thread-id/11431#M11473)
- 🔗 [Elechouse PN7160 模块](https://www.elechouse.com/product/pn7160-nfc-rfid-module/)
- 🔗 [Elechouse I2C 快速指南](https://www.elechouse.com/wp-content/uploads/2024/06/Quick-Guide-I2C.pdf)

### OpenWrt 相关
- 🔗 [OpenWrt 软件包指南](https://openwrt.org/docs/guide-developer/packages)

---

## 💬 支持

## 💬 支持

对于以下相关问题：

| 问题类型 | 寻求帮助 |
|---------|---------|
| 🔨 **软件包构建** | 查看 OpenWrt 论坛 |
| 📡 **NFC 功能** | 参考 NXP 文档 |
| 🔧 **PN7160 硬件** | 查看 NXP 社区论坛 |
