# iPadOS 适配前置分析

本文档用于记录星语音乐盒 Apple/iOS 工程在 iPadOS 适配前的结构分析与方案建议。当前阶段只做分析和方案，不改播放核心逻辑，不改星语音库 OpenAPI 调用逻辑，不做大规模重构。

## 当前结论

- 当前 Xcode target 已配置为 Universal App：`TARGETED_DEVICE_FAMILY = "1,2"`，即同时支持 iPhone 与 iPad。
- 工程 iOS 部分位于 `apps/apple/ios/`，工程名、Target、Scheme、Bundle Identifier 与 Swift 模块名仍保持 `XingyuMusicBox`。
- 当前主界面明显以 iPhone 单列体验为中心：`ContentView` 使用自定义底部 Tab 切换页面，歌曲列表内部使用 `NavigationStack`，播放页使用分页 `TabView` 展示最近播放、封面播放页和歌词页。
- 当前 iPadOS 适配方向调整为整屏播放器优先：iPad 宽屏展示播放器左右分区，本地音乐与最近播放通过右侧面板进入；iPhone 与窄分屏保持现有单列底部 Tab 体验。

## 工程配置检查

已检查 `apps/apple/ios/XingyuMusicBox.xcodeproj/project.pbxproj`：

- `TARGETED_DEVICE_FAMILY = "1,2"`：已支持 iPhone 与 iPad。
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0`：满足使用 `NavigationSplitView`、`NavigationStack` 等现代 SwiftUI API 的最低要求。
- iPad 方向支持包含：
  - `UIInterfaceOrientationPortrait`
  - `UIInterfaceOrientationPortraitUpsideDown`
  - `UIInterfaceOrientationLandscapeLeft`
  - `UIInterfaceOrientationLandscapeRight`
- iPhone 方向支持包含：
  - `UIInterfaceOrientationPortrait`
  - `UIInterfaceOrientationLandscapeLeft`
  - `UIInterfaceOrientationLandscapeRight`

建议暂不修改 Bundle Identifier、Target、Scheme、模块名。后续如果拆分多平台 target，再单独评估命名与目录。

## 当前主要页面结构

### 应用入口

- `XingyuMusicBoxApp` 创建 `PlayerViewModel` 与 `ThemeManager`，通过 environment 注入 `ContentView`。
- 播放状态、歌曲列表、收藏、最近播放、歌词缓存刷新等状态集中在 `PlayerViewModel` 与相关服务中。

### 根视图

- `ContentView` 是当前根容器。
- 使用 `selectedTab: AppTab` 管理四个页面：
  - `NowPlayingView`
  - `SongListView`
  - `FavoriteSongsView`
  - `SettingsView`
- 底部使用自定义 `XingyuTabBar`，适合 iPhone，但在 iPad 横屏会占用底部空间，且无法利用侧边栏。
- 顶部 toast 与 scene phase 逻辑位于根视图，应在 iPad 根布局中继续保留。

### 歌曲列表

- `SongListView` 当前使用 `NavigationStack`。
- 内部支持歌曲、歌手、专辑三种浏览方式。
- 主要 UI 包括：
  - 顶部标题、刷新按钮、排序菜单
  - 分段 Picker
  - 搜索框
  - 媒体库授权/状态卡片
  - 歌曲列表、歌手分组、专辑分组
  - 当前播放定位按钮
  - 底部 `MiniPlayerView`
- 歌手/专辑详情使用 `NavigationLink` 推入 `LocalMusicGroupDetailView`。

### 播放页

- `NowPlayingView` 当前是一个单列播放中心。
- 有顶部品牌 header。
- 有三页分页内容：
  - `RecentHistoryPageView`：最近播放
  - `CoverPlayerPageView`：封面、元数据、歌词预览、进度条、播放控制
  - `LyricsPageView`：完整歌词、LRC 滚动、歌词搜索与删除
- 该结构在 iPhone 上自然，但 iPad 横屏更适合把封面播放器、歌词、最近播放并列展示。

### 歌词页

- `LyricsPageView` 已相对独立，入参是歌曲、播放时间、播放状态与控制闭包。
- 内部负责：
  - 获取缓存歌词
  - 读取媒体库歌词
  - LRC 解析与当前行定位
  - 歌词搜索 sheet
  - 删除缓存歌词 confirmation dialog
- 这部分适合直接复用到 iPad 详情区，但需要控制高度、滚动区域与底部迷你控制条的位置。

### 收藏页

- `FavoriteSongsView` 使用收藏歌曲过滤后的列表。
- 复用 `SongRowView` 与 `MiniPlayerView`。
- 结构和本地歌曲列表接近，适合作为 iPad 侧边栏中的一个列表源，或作为第二列列表内容。

### 设置页

- `SettingsView` 是单列 `ScrollView`，包含多个 `settingsCard`。
- 当前包含主题、音乐库、星语音库联调、系统媒体库测试、歌词测试、数据管理、播放器说明与版本信息。
- 设置页在 iPad 上适合居中限制最大宽度，或作为 split view 的 detail 页面展示，不建议横向铺满整屏。

## 适合抽成可复用组件的区域

### 必须优先复用

- `SongRowView`：歌曲列表、收藏、歌手/专辑详情都在使用，可继续作为 iPad 列表基础行。
- `MiniPlayerView`：iPhone 底部浮动播放器可保留；iPad 可改为侧边栏或详情底部的紧凑播放条。
- `CoverView`：封面展示已支持媒体库与星语音库封面查询，适合继续复用。
- `PlayerControlsView`：播放控制不应重复实现，iPad 详情区直接复用。
- `ProgressSliderView`：进度条继续作为共享播放控制组件。
- `LyricsPageView` 及其内部歌词 timeline 子组件：适合在 iPad 右侧/详情区复用。

### 建议逐步抽出

- `AppTheme`、`ThemeManager`、`XYStyle`：目前放在 `ContentView.swift`，后续多端演进时建议拆到 `Theme/` 或 `DesignSystem/`。
- `XingyuTabBar`、`XingyuTabBarItem`：保留给 iPhone root；iPad root 改用 sidebar 后，可将其作为独立 `Components`。
- `LocalMusicBrowseMode`、歌手/专辑分组模型、`ArtistGroupRowView`、`AlbumGroupRowView`、`LocalMusicGroupDetailView`：建议从 `SongListView.swift` 拆到本地音乐浏览模块，便于 iPad 列表列复用。
- `settingsCard`、`SettingsRow`、`SettingsActionButton`、`SettingsDivider`：设置页已经组件化，但部分是 private，可按需要提升可见性。
- `RecentHistoryPageView`：可作为 iPad 辅助面板，展示在详情页右侧或底部。

### 暂不建议抽动

- `MusicVaultApiClient`、`MusicVaultMetadataService`、`MusicVaultArtworkService`、`MusicVaultLyricsService`：本次 iPadOS 适配不应改 OpenAPI 调用逻辑。
- `MusicPlayer`、`AudioSessionManager`、`RemoteCommandManager`、`NowPlayingInfoManager`：本次不改播放核心逻辑。
- `PlayerViewModel` 的播放与接口行为：可以新增 UI 状态，但避免重写播放、歌词、封面、元数据联动逻辑。

## iPadOS 响应式布局方案

### 总体原则

- iPhone 与窄分屏继续使用当前单列底部 Tab 体验。
- iPad 横屏、全屏和宽分屏优先展示整屏播放器。
- iPad 竖屏可以使用 split view，但需要允许系统自动折叠；不要强行三列。
- iPad 分屏要按可用宽度判断，而不是只按设备类型判断。
- 播放能力与数据请求仍通过现有 `PlayerViewModel` 和服务层驱动。

### 建议根布局

新增一个轻量根容器，例如 `AdaptiveRootView`：

- 使用 `@Environment(\.horizontalSizeClass)` 与 `GeometryReader` 判断布局。
- 当宽度较窄或 horizontal size class 为 compact 时，展示当前 `ContentView` 的 iPhone 布局。
- 当宽度足够时，展示 iPad split 布局。

建议阈值：

- `< 700pt`：使用 iPhone 单列布局。
- `700pt - 859pt`：进入 iPad root，但播放页内部回退原分页体验，避免竖屏上下布局造成新的割裂感。
- `>= 860pt`：启用 iPad 播放器左右分区。

### iPad 播放主页结构

当前不再使用左侧 sidebar 作为 iPad 主入口，播放主页优先占满可用空间：

- 左侧：封面、歌曲信息、进度条、播放控制和快捷操作。
- 右侧：歌词展示和歌词相关操作。
- 播放列表入口：从播放主页打开右侧侧向面板。
- 面板分页：本地音乐列表与最近播放列表。
- 窄分屏：回退原 `NowPlayingView`。

### 播放详情 iPad 排版

`NowPlayingView` 在 iPad 上建议从分页改为并列：

- 左侧：封面、歌曲信息、进度条、播放控制、快捷操作
- 右侧：歌词完整视图
- 辅助区域：最近播放可放在左侧下方、右侧上方 tab，或作为 sidebar/content 列表

横屏全屏推荐：

- 40% 宽度：`CoverPlayerPageView` 核心内容
- 60% 宽度：`LyricsPageView`
- 最近播放作为侧边列表或底部抽屉，避免三块内容同时挤压。

竖屏推荐：

- 上半区：封面和播放控制
- 下半区：歌词
- 最近播放通过 toolbar 或 segmented control 切换，不强行三列。

分屏推荐：

- 宽度不足时自动回退到当前分页 `TabView`。
- 仅在宽度足够时展示并列内容。

### 歌曲列表 iPad 排版

本地歌曲页适合拆成：

- `SongBrowserHeader`：标题、刷新、排序、浏览方式、搜索。
- `SongBrowserList`：歌曲/歌手/专辑列表。
- `SongGroupDetail`：歌手或专辑详情。

iPad 上：

- Sidebar 或 content 列展示歌曲列表。
- Detail 列展示当前播放详情。
- 点击歌曲后直接播放，同时 detail 保持/切换到播放页。
- 点击歌手/专辑后，在 content 列或 detail 列展示分组详情，避免深层 push 后丢失播放上下文。

### 设置页 iPad 排版

设置页不需要复杂 split。

建议：

- 在 iPad detail 中限制最大宽度，例如 720pt - 820pt。
- 保持 `ScrollView`，避免卡片横向拉伸过宽。
- 星语音库联调与系统媒体库测试属于调试密度较高的区域，后续可拆到“诊断”分组。

## 保持 iPhone 体验不被破坏的策略

- 不替换现有 `ContentView` 的 iPhone 行为，而是在更外层做自适应分发。
- 当前自定义底部 Tab、MiniPlayer 底部 padding、播放页分页 `TabView` 都保留给 compact 布局。
- 新增 iPad 布局时优先复用现有子 View，而不是改写现有页面。
- 所有新增布局判断基于 size class 与实际宽度，覆盖 iPad 分屏。
- 不改变 `PlayerViewModel` 中的播放、收藏、歌词缓存、星语音库请求逻辑。
- iPad 相关 UI 状态应尽量局部化，例如 selectedSidebarItem、selectedSong、columnVisibility。

## 风险点

- 当前部分视图使用固定底部 padding，例如列表页底部为 MiniPlayer 与 TabBar 预留空间。iPad split 布局中如果继续套用这些页面，可能出现底部空白过大。
- `NowPlayingView` 的 `TabView` 在 iPad 横屏会浪费空间，且歌词与封面不能同时可见。
- `CoverPlayerPageView` 的封面尺寸主要根据高度计算，iPad 横屏/分屏时需要确认不会过小或过大。
- `SettingsView` 内容较长，横向全屏展示会显得松散，需要最大宽度约束。
- `SongListView` 内部自带 `NavigationStack`，放入 `NavigationSplitView` 时可能出现导航层级嵌套，需要逐步拆出列表主体。
- 当前文案中多处写了“iPhone 系统媒体库”，iPadOS 适配时建议改为“系统媒体库”或“本机系统媒体库”。

## 最小改动建议

- 新增 `AdaptiveRootView`，由 `XingyuMusicBoxApp` 加载；compact 时仍展示现有 `ContentView`。
- 新增 `IPadRootView`，作为 iPad 整屏播放器入口。
- 将 `ContentView` 中的 `AppTab`、`XingyuTabBar` 保持不动，作为 iPhone 专用导航。
- 从 `SongListView` 逐步抽出列表主体，先不改播放逻辑。
- iPad 专用播放详情先暂缓；后续如继续优化，再考虑为 `NowPlayingView` 增加布局模式入参或新增稳定的 iPad 播放详情视图。
- 把“iPhone 系统媒体库”文案逐步改成平台中性文案，但不要在第一步混入功能重构。

## 后续实现任务拆分

### 必须项

1. 新增自适应根容器：根据 size class 与宽度选择 iPhone 单列布局或 iPad split 布局。
2. 新增 iPad 整屏播放器入口，默认不展示左侧导航。
3. 先稳定复用现有播放详情页；后续再单独设计 iPad 播放详情页。
4. 保留 iPhone `ContentView` 现有底部 Tab 行为，避免影响当前体验。
5. 对 `SongListView` 的底部 MiniPlayer/TabBar 预留空间做布局条件化，避免 iPad 空白过大。
6. 在 iPad 竖屏、横屏、1/2 分屏、1/3 分屏下做手工验证。
7. 验证 `xcodebuild -list`、Xcode 打开工程、iPhone 模拟器运行与 iPad 模拟器运行。

### 可选项

1. 将 `AppTheme`、`ThemeManager`、`XYStyle` 拆到独立设计系统文件。
2. 将 `SongListView` 拆成 header、browser list、group detail 等更小组件。
3. 将 `SettingsView` 的诊断区域拆成独立 `DiagnosticsView`。
4. 为 iPad 增加当前队列/最近播放辅助栏。
5. 为 iPad 增加 toolbar 快捷操作，例如刷新媒体库、主题切换、歌词搜索。
6. 引入预览场景，覆盖 iPhone portrait、iPad portrait、iPad landscape、split width。
7. 将平台文案统一为“系统媒体库”，减少 iPhone-only 表述。

## 实现一期进展

一期实现已建立 iPadOS 基础自适应布局骨架，重点是接入新根布局、保留 iPhone 体验、复用现有页面与播放组件。

### 新增视图职责****

- `AdaptiveRootView`：新的应用根视图，由 `XingyuMusicBoxApp` 加载；根据 `horizontalSizeClass`、实际宽度和设备类型判断布局。iPhone、compact 布局和 `< 700pt` 的窄宽度继续展示现有 `ContentView`，iPad 宽屏展示 `IPadRootView`。
- `IPadRootView`：iPad 专用根视图。当前不再展示左侧 sidebar，进入 iPad 宽屏后整屏让位给播放器；本地音乐与最近播放通过播放器里的右侧面板进入。

### 已完成的最小适配

- `XingyuMusicBoxApp` 已从直接加载 `ContentView` 调整为加载 `AdaptiveRootView`。
- `ContentView` 的 iPhone 自定义底部 Tab、MiniPlayer 和分页播放页逻辑保持原样。
- `SongListView` 与 `FavoriteSongsView` 增加轻量布局上下文，用于在 iPad split 中缩小底部预留空间，避免沿用 iPhone TabBar/MiniPlayer 留白。
- `SettingsView` 增加可选最大内容宽度，iPad detail 中限制为约 820pt，避免横向铺满过松。
- 少量平台文案已从“iPhone 系统媒体库”调整为“本机系统媒体库”或“系统媒体库”。
- Xcode 工程已加入新增 Swift 文件引用，未修改 Target、Scheme、Bundle Identifier 或 Swift 模块名。

## 第一版交互问题与修正策略

第一版 iPadOS 适配尝试在“正在播放”页中并排展示封面播放器、歌词和最近播放。该方向虽然能利用 iPad 横屏空间，但在基础适配阶段带来了过多交互变量：播放页分页、歌词滚动、最近播放列表、sidebar 切换和分屏宽度变化同时叠加，容易造成操作路径不稳定。

本次修正选择先收敛布局复杂度：

- iPad 入口不再展示左侧 sidebar，整屏优先给播放器。
- 本地音乐和最近播放从播放器里的右侧面板进入。
- 宽屏播放主页使用左右分区；窄分屏继续回退原 `NowPlayingView`。
- 暂不做三栏结构，暂不把歌曲列表、歌词和播放详情强行并列联动。
- 暂不重构 `SongListView` 的深层 `NavigationStack`。
- iPad 窄分屏、compact size class、宽度 `< 700pt` 时继续回退到现有 `ContentView`。

这样做的原因是：v0.2.0 当前优先目标是让 iPad 入口稳定可用，而不是一次性完成完整 iPad 信息架构。基础入口先保护 iPhone 现有体验，再逐步把 iPad 播放主页打磨清楚。

根据后续细节讨论，当前 iPad 入口进一步调整为“整屏播放器优先”：进入软件后不再显示左侧“正在播放 / 本地歌曲 / 收藏 / 设置”导航，把整屏空间让给右侧播放器。列表能力改为从播放器触发右侧面板承载。

继续根据细节讨论，原“收藏”“设置”页面暂时不再作为左侧导航项出现，而是做成播放器顶部按钮，放在“播放列表”旁边。点击“播放列表”“收藏”“设置”都会从右侧打开抽屉，保持播放主页上下文不被切走。

### 本次交互修正

- `IPadRootView` 已移除左侧 sidebar，直接加载 iPad 播放主页。
- `IPadRootView` 不再负责页面切换；iPad 本地音乐与最近播放入口由播放主页右侧面板承载。
- iPad 播放主页顶部新增“播放列表”“收藏”“设置”三个入口，统一从右侧抽屉打开。
- `FavoriteSongsView` 的 iPad 布局参数保留，但当前 iPad 收藏入口使用轻量收藏抽屉，复用 `SongRowView` 与 `PlayerViewModel` 播放能力。
- `SettingsView` 的最大宽度参数保留，iPad 设置抽屉内继续复用现有 `SettingsView`。

### 仍未解决的问题

- `SongListView` 内部仍包含自己的 `NavigationStack`。目前先不拆，后续如发现 split 内 push 层级体验不佳，再拆出列表主体和分组详情。
- 当前 iPad 宽屏已进入 `IPadNowPlayingView`，但窄宽度仍会回退原 `NowPlayingView`。
- iPad 横屏、竖屏、1/2 分屏、窄分屏仍需要在可用模拟器或真机上补充手工验证。
- 如果后续继续推进宽屏体验，应优先继续打磨 `IPadNowPlayingView`，避免扩大到复杂多栏重构。

### 参考图启发与后续方向

用户提供的两张 iPad 播放器参考图可以作为后续 iPadOS 体验方向，但不应完全照抄视觉、控件或交互细节。

可借鉴的方向：

- 播放主页可以采用左右分区：左侧聚焦封面、歌曲信息、进度条与播放控制，右侧展示歌词。
- 本地音乐列表可以从播放页触发，以侧向面板或抽屉形式出现，保留播放页上下文。
- 列表面板可以支持左右滑动或分页切换：一页展示本地音乐列表，另一页展示最近播放列表。
- iPad 横屏下可以让播放、歌词、列表形成“当前播放上下文 + 辅助内容”的关系，而不是简单放大 iPhone 页面。

本次已按这个方向做轻量改良，但仍保持“不照抄、不重构核心逻辑”的边界：

1. `IPadNowPlayingView` 在 iPad 宽屏下展示左右分区：左侧复用 `CoverPlayerPageView`，右侧复用 `LyricsPageView`。
2. 宽度或高度不足时继续回退原 `NowPlayingView`，保留现有分页播放页。
3. 播放列表入口改为右侧侧向面板，展示“本地音乐”和“最近播放”两个分页。
4. 列表面板支持左右滑动切换分页，并保留顶部搜索。
5. 本地音乐和最近播放列表复用现有 `SongRowView`、`RecentHistoryRowView` 与 `PlayerViewModel` 播放入口，不修改播放核心。
6. “收藏”“设置”也改为播放主页顶部按钮，从右侧抽屉打开；收藏抽屉复用歌曲行，设置抽屉复用现有设置页。
7. 播放主界面不再做成两个强烈分离的卡片，而是使用一个统一播放器容器，封面控制区和歌词区之间不再放明显分隔线。
8. iPad 宽屏播放主页左侧隐藏三行歌词预览，因为右侧已经同步展示完整歌词；iPhone 原播放页仍保留该预览。
9. iPad 宽屏右侧歌词区隐藏底部迷你控制器，避免同一页面内出现两套播放控制；iPhone 原歌词页仍保留该控制器。
10. iPad 竖屏或中等宽度下暂不使用上下布局，回退原 `NowPlayingView`，避免竖屏体验割裂。
11. iPad 宽屏播放主页去掉整体玻璃框线，避免播放器被框住显得局促。
12. 左侧“收藏 / 列表 / 音效 / 皮肤”快捷按钮改为横排放在封面下方；歌曲信息压缩为标题一行、歌手与专辑/年份一行。
13. iPad 宽屏左侧封面控制区加宽，右侧歌词区适当收窄，让页面视觉重心更接近参考图。
14. iPad 宽屏右侧歌词启用专用展示风格：歌词滚动区域顶部和底部做渐淡遮罩，LRC 行间距变得更疏朗，当前行更醒目，非当前行更轻，避免歌词区显得拥挤。

后续仍需继续验证：

1. iPad 横屏、竖屏、1/2 分屏、窄分屏下侧向面板宽度是否自然。
2. 歌词页底部迷你控制条与左侧播放控制是否会造成重复控制感。
3. 如果列表面板承载更多操作，再评估是否抽成独立文件，避免 `IPadRootView.swift` 继续膨胀。
4. 窄分屏仍优先回退 `ContentView`，不要为了视觉效果牺牲交互稳定性。

### 保持未改的边界

- 未修改 `MusicVaultApiClient`、`MusicVaultMetadataService`、`MusicVaultArtworkService`、`MusicVaultLyricsService`。
- 未修改 `MusicPlayer`、`AudioSessionManager`、`RemoteCommandManager`、`NowPlayingInfoManager`。
- 未引入 macOS、Android、Windows 代码。
- 未做 App Store 或 TestFlight 相关改动。

### 验证记录

- `xcodebuild -list -project apps/apple/ios/XingyuMusicBox.xcodeproj` 可识别 `XingyuMusicBox` target 与 scheme。
- 不签名 generic iOS build 已尝试执行，但当前本机环境 `CoreSimulatorService` / simulator runtimes 不可用，构建在 Asset Catalog 编译阶段失败，错误为 `No available simulator runtimes for platform iphonesimulator`。该失败与本次 SwiftUI 改动无明显直接关系。
- 由于当前环境模拟器服务不可用，iPhone 模拟器运行、iPad 模拟器运行、iPad 横屏/竖屏/窄分屏手工验证尚未完成，需要在本机 Xcode 模拟器环境恢复后补测。

## 本阶段不做

- 不修改星语音库 OpenAPI 调用逻辑。
- 不修改播放核心逻辑。
- 不重命名工程、Target、Scheme、Bundle Identifier 或 Swift 模块。
- 不引入 Android、Windows 或 macOS 代码。
- 不做 App Store / TestFlight 发布承诺。
