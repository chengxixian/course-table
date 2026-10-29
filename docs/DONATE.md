# 赞赏码说明

本仓库的 `assets/` 下有两张赞赏二维码：

| 文件 | 用途 |
| --- | --- |
| `assets/donate_wechat.png` | 微信赞赏 |
| `assets/donate_alipay.jpg` | 支付宝 |

它们**不是**占位图、示例素材或可随意替换的演示资源，而是作者本人的个人收款二维码。两张图片由「关于」页直接读取展示，并在 `pubspec.yaml` 的 `flutter.assets` 中声明，因此会随应用一起打包。

## 为什么保留在仓库中

- 这是个人项目的真实赞赏入口，便于用户直接支持作者；
- 保持源码与发布构建一致，避免「仓库里是示例图、发布包却是另一张图」的不透明行为；
- 赞赏完全自愿，与应用功能、课表数据、更新服务均无关联。

## 使用规则

1. **未经作者明确许可，不得替换**这两张二维码，包括但不限于：换成自己的收款码、换成其他第三方二维码、用占位图或空白图覆盖、裁剪、遮挡、重绘或合成。
2. 不得将本项目（源码或重新打包的 APK / Windows 构建）中的赞赏码替换为其他收款账户后对外分发或收款。
3. Fork、二次开发或其他衍生版本：可以为个人本地构建保留原图；**公开分发前应移除赞赏入口**，或先取得作者许可。移除时需同步修改 `pubspec.yaml` 的资源声明与 `lib/ui/about_screen.dart` 中的展示逻辑。
4. 不得以本项目、黄山学院或任何官方机构的名义，利用该赞赏码进行募捐、收费或误导性宣传。
5. 赞赏是自愿赠与，不构成付费服务、购买凭证、捐赠票据或任何形式的权益承诺；作者不对赞赏行为提供退款或对价。

## 许可范围

- 源代码采用 [GNU General Public License v3.0](../LICENSE) 授权。
- 赞赏二维码图片、作者姓名 / 标识、项目图标与名称**不随 GPL-3.0 源代码许可授权**，相关权利由作者保留。
- 字体 `assets/FusionPixel12.ttf` 与 `assets/Pixelarticons.ttf` 遵循其各自的上游许可证，不属于本项目 MIT 授权范围。

## 更新与授权

如二维码失效、需要更换，或希望在自己的衍生项目中使用，请通过 [GitHub Issues](https://github.com/chengxixian/course-table/issues) 联系作者取得许可。只有作者本人可以更新这两张图片。

## 安全提示

- 扫码前请确认页面来源是本仓库或作者发布的官方安装包；
- 除上述两张图片外，本项目不会通过其他二维码、私信或群聊索要款项；
- 若发现被篡改的衍生版本，请通过 Issues 告知作者。

---

## English note

`assets/donate_wechat.png` and `assets/donate_alipay.jpg` are the author's **personal** payment QR codes, not placeholder/demo assets. They are bundled intentionally and displayed on the About screen.

**Do not replace, crop, cover, redraw, or reuse these images without the author's explicit permission.** Forks and redistributions must either keep them untouched or remove the donation entry (updating `pubspec.yaml` and `lib/ui/about_screen.dart` accordingly) before public release. They are not covered by the GPL-3.0 source license; all rights are reserved by the author.
