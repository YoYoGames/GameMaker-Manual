# GameMaker 手册

欢迎查看GameMaker手册的源文件。 [从此处查看其他语言版本](https://github.com/topics/gm-manual).

本手册使用 Adobe RoboHelp 2022.0.346 制作而成。建议使用 RoboHelp 来修改本手册。

您可以在 RoboHelp 中打开项目文件，该文件位于[/Manual/GMS2_Manual.rhpj](/Manual/GMS2_Manual.rhpj)中。

第二种推荐的方法是直接编辑位于 [/Manual/contents](/Manual/contents)目录下的 HTML 文件。

⚠️ 如果您使用程序对HTML文件进行了不合规的修改，您的代码提交将会被拒绝。

### 在编辑手册时请务必谨慎。

:hand: 注意现有文本中使用的写作和格式风格，并确保您的添加/修改内容与之保持一致。

:wrench: 若要进行更改，建议您先fork一个分支，然后将其克隆至本地编辑，这样您就可以在浏览器中测试您的 HTML 代码了。

:white_check_mark: 完成后，请将更改推送到 GitHub 上您的分支，并创建一个拉取请求。

### 提醒

1. 这份手册源文件不是打算直接提供给用户的 (例如下载此代码库并将HTML文件作为GameMaker手册来阅读)，它的作用是生成手册。最终的用户版本手册可以在 [the manual website](https://manual.gamemaker.io) 在线查看，也可以在IDE中下载(在 *偏好设定* -> *常规选项* -> *帮助* 中使用离线手册选项)。

2. 请不要更改HTML文件中带 `<span data-keyref>` 标签的内容，这些是RoboHelp变量，不应手动编辑。正确的内容将在构建手册时由RoboHelp插入（内容来自Manual/variable/Default.var文件）。

3. 如果需要修改这些变量，请转到 Manual/variable/Default.var文件，在那里对变量进行修改（例如修正数据类型的链接）。

4. 同样， `<span data-conref>` 标签中的内容不能直接编辑，因为它们是在生成手册时插入的代码片段(snippets)。这些片段取自 Manual/contents/assets/snippets/ 目录。
