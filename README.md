# 吃货达人

一个按照 `吃货达人_APP_PRD.md` 实现的 iPhone 原生 SwiftUI MVP。

## 已实现

- SwiftUI + SwiftData 本地优先 App 骨架
- 首页美食日志流、搜索和快捷筛选
- 新建探店草稿自动保存
- 照片选择、本地存储、封面卡片展示
- 店名、类型、评分、推荐菜、口述点评录入
- 大众点评/高德字段的模拟自动补全和手动兜底
- AI 美食日志异步模拟生成、可编辑、可重新生成
- “吃啥”页基于本地记录做筛选推荐
- 默认地点隐私保护，仅展示街区/保护状态

## 打开方式

用 Xcode 打开：

```sh
open ChiHuoDaRen.xcodeproj
```

当前机器只有 Command Line Tools，没有完整 Xcode，因此这里无法运行 iOS 模拟器构建。

## 验证

```sh
Scripts/verify.sh
```

脚本会验证工程格式、资源 JSON、Swift 语法和核心 PRD 流程。安装完整 Xcode 后，脚本会继续尝试 iOS 模拟器构建。
