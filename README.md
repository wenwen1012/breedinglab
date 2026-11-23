# BreedingLab｜飞书单文档自动同步测试

本仓库用于验证 **飞书文档 → GitHub Actions → Markdown → Hugo → GitHub Pages** 自动化流程。

## 内容源

目前只同步这一份飞书知识库文档：

- https://a2eb1ewtyj.feishu.cn/wiki/UQPnwnoiciRYcKk3SB3ckR4snzb

配置位置：`sync/docs.yaml`

生成文件：`content/docs/breedinglab.zh.md`（由自动化覆盖，不要手工编辑）。

## 一次性配置

### 1. 飞书自建应用

在飞书开放平台创建企业自建应用，并按 feishu2md 项目说明开通权限：

- `docx:document:readonly`：读取新版文档及文档块
- `docs:document.media:download`：下载文档图片和附件
- `drive:file:readonly`：读取云空间文件清单
- `wiki:wiki:readonly`：读取知识库节点

将应用发布，并确保应用已获得目标知识库/文档的访问权限。

参考：https://github.com/Wsine/feishu2md

### 2. GitHub Actions Secrets

仓库 Settings → Secrets and variables → Actions → New repository secret：

- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`

不要把密钥写入仓库文件或提交到 Git。

### 3. 启用 GitHub Pages

仓库 Settings → Pages → Build and deployment → Source 选择 **GitHub Actions**。

## 运行方式

- 定时：每 4 小时运行一次。
- 手动：Actions → Sync Feishu document and publish site → Run workflow。

同步和网站部署在同一个 workflow 中执行，避免 `GITHUB_TOKEN` 推送提交不会触发另一个 `push` workflow 的问题。

网站地址：

https://wenwen1012.github.io/breedinglab/

## 注意事项

- 本 MVP 只同步一个飞书文档。
- 第一次运行前必须配置两个 Secrets 和飞书应用权限。
- 飞书文档中的复杂画板、部分嵌入内容可能无法完整转换；首次运行后需检查图片、附件和排版。
- `feishu2md` 是社区维护项目，工具版本和飞书 API 变化可能影响同步。
