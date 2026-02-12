# bm-cli Homebrew 支持说明

本目录提供 `bm-cli` 的 Homebrew tap 接入模板，参考了 `LeviTK/homebrew-tap` 的组织方式（`Formula/*.rb`）。

## 1. 推荐仓库结构

建议单独创建 tap 仓库，例如：

```text
homebrew-tap/
  README.md
  Formula/
    bm-cli.rb
```

然后将本目录中的 `Formula/bm-cli.rb` 复制到 tap 仓库对应位置。

## 2. Release 产物约定

`bm-cli` 主仓库发布时，建议提供以下 macOS 二进制压缩包：

- `bm-cli-darwin-arm64.tar.gz`
- `bm-cli-darwin-x64.tar.gz`

每个压缩包至少包含：

- `bm-cli` 可执行文件

## 3. 计算 SHA256

在发布产物下载后执行：

```bash
shasum -a 256 bm-cli-darwin-arm64.tar.gz
shasum -a 256 bm-cli-darwin-x64.tar.gz
```

将得到的哈希写入 `Formula/bm-cli.rb`。

## 4. 用户安装方式

```bash
brew tap <owner>/tap
brew install <owner>/tap/bm-cli
```

## 5. 每次发布必做项

1. 更新 Formula 的 `version`。
2. 更新 arm64/x64 两个 `sha256`。
3. 提交并推送 tap 仓库。
4. 在干净环境执行安装验证。

## 6. 建议的发布策略

- 主仓库：负责构建并上传 release 二进制产物。
- tap 仓库：只维护 `Formula/bm-cli.rb`。
- 优先安装预编译二进制，减少用户环境依赖与安装时间。
