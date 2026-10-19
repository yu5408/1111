# 不用Mac！GitHub Actions 自动编译教程

## 什么是GitHub Actions？

简单说：GitHub的云端服务器帮你编译代码，你只需要点一下按钮，编译好的dylib直接下载就行。

全程免费，不用装任何软件。

---

## 第一步：注册GitHub账号（如果还没有）

1. 打开 https://github.com
2. 点 Sign up 注册一个免费账号

---

## 第二步：创建新仓库

1. 登录后，点右上角 + 号 → New repository
2. 仓库名随便填，比如 `cmcc-adblock`
3. 选 Public（公开）
4. 点 Create repository

---

## 第三步：上传代码

把 `ChinaMobileAdBlock` 文件夹里的所有文件上传到这个仓库：

需要上传的文件：
- `Makefile`
- `ChinaMobileAdBlock.xm`
- `Filter.plist`
- `control`
- `.github/workflows/build.yml`（注意要先建.github文件夹）

**操作方法：**
1. 在仓库页面点 "uploading an existing file"
2. 把文件拖进去
3. 点 Commit changes

---

## 第四步：触发编译

1. 上传完文件后，点仓库上方的 "Actions" 标签
2. 左边选 "Build Tweak"
3. 点右边的 "Run workflow" 按钮
4. 再点绿色的 "Run workflow"

---

## 第五步：下载编译好的dylib

1. 等1-2分钟，编译完成
2. 点进去那个成功的构建记录
3. 拉到最下面，Artifacts 区域
4. 下载 `ChinaMobileAdBlock-dylib`
5. 解压就能看到 `libChinaMobileAdBlock.dylib`

---

## 第六步：用TrollFools注入到中国移动APP

1. 把 `libChinaMobileAdBlock.dylib` 传到手机的"文件"APP里
2. 打开 TrollFools
3. 找到中国移动APP，点进去
4. 点 + 号，选择刚才的dylib
5. 注入完成，重启中国移动APP

---

## 常见问题

### Q: 编译失败了怎么办？
A: 把失败的日志截图发给我，我帮你看。

### Q: 编译出来的dylib用不了怎么办？
A: 可能是架构问题，我可以调整Makefile，改成只编译arm64（你的14PM是arm64e，但arm64也兼容）。

### Q: 每次更新都要重新编译吗？
A: 对，改了代码就重新跑一下Actions就行。

---

## 为什么不用WSL/Cygwin？

因为太麻烦了，要装一堆东西，还容易出错。GitHub Actions 是最省事的方案，全程浏览器操作。
