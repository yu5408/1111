# ChinaMobileAdBlock - 中国移动APP 开屏广告深度去除插件

## 项目说明

专门针对中国移动APP（cn.10086.app）的开屏广告去除插件。采用**四层拦截策略**，确保各种情况下都能有效拦截广告。

## 为什么中国移动的广告难屏蔽？

中国移动的开屏广告比较顽固，主要特点：
1. **延迟加载**：不是启动就显示，而是等网络请求返回后才弹出
2. **多种展示形式**：可能是全屏VC、可能是window上的view
3. **类名混淆**：广告相关类名经常变化
4. **摇一摇跳转**：检测到设备晃动就跳广告

## 四层拦截策略

| 层级 | 拦截方式 | 说明 |
|------|----------|------|
| **第1层：控制器层** | Hook `presentViewController:` | 直接拦截广告VC的弹出 |
| **第2层：视图层** | 特征识别 + 类名匹配 | 检测跳过按钮、倒计时等特征 |
| **第3层：网络层** | Hook NSURLSession | 拦截广告API请求，返回空数据 |
| **第4层：兜底检测** | 启动后多次扫描 | 应对延迟加载的广告 |

## 特征识别原理

即使类名变了，也能通过以下特征识别广告：
- 视图中包含**"跳过"按钮**
- 视图中包含**倒计时标签**（如"3秒后关闭"）
- 全屏模态展示 + 有广告特征

## 环境要求

### 方式一：越狱设备
- iOS 14.0+
- 已越狱（Dopamine / Taurine 等）
- Theos 编译环境

### 方式二：巨魔设备
- iOS 15.0 - 17.0（支持的版本）
- TrollStore + TrollFools

## 编译方法

```bash
export THEOS=~/theos
cd ChinaMobileAdBlock
make package
```

## 部署方式

### 越狱设备
```bash
make install THEOS_DEVICE_IP=你的设备IP
```

### 巨魔设备
1. 编译得到 `libChinaMobileAdBlock.dylib`
2. 用 TrollFools 注入到中国移动APP
3. 重启中国移动APP生效

## 调试方法

### 查看日志
```bash
tail -f /var/log/syslog | grep CMCCAdBlock
```

### 自定义适配

如果更新后失效了，需要找到新的广告类名：

1. 用 Cycript 注入中国移动APP
2. 打开开屏广告
3. 执行：
```cycript
[[UIApplication sharedApplication].keyWindow recursiveDescription]
```
4. 找到广告相关的类名
5. 添加到 `kAdClassKeywords` 数组中

## 已适配的广告SDK

- 咪咕SDK开屏广告
- 自研开屏广告系统
- 穿山甲/GDT等第三方SDK
- 未知SDK（通过特征识别兜底）

## 注意事项

1. **APP更新后可能失效**：类名和接口可能变化，需要更新适配
2. **不要过度拦截**：只拦截开屏广告，不影响正常功能
3. **先测试**：建议先在测试设备上验证，避免闪退
4. **法律风险**：去广告可能违反用户协议，请自行承担

## 文件结构

```
ChinaMobileAdBlock/
├── Makefile              # 编译配置
├── ChinaMobileAdBlock.xm # 核心代码
├── Filter.plist          # 目标APP配置（已设为 cn.10086.app）
├── control               # deb包描述
└── README.md             # 本文件
```

## 后续优化方向

- [ ] 添加摇一摇广告拦截
- [ ] 添加首页弹窗广告拦截
- [ ] 添加设置界面开关
- [ ] 支持自动更新规则
