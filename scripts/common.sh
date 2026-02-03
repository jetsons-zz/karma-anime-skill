#!/bin/bash
# Karma Anime - 公共配置
# 被其他脚本 source 引用，不要直接执行

# 加载环境变量（若存在）
if [[ -f "${HOME}/.bashrc" ]]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bashrc"
fi

# API 配置
API_KEY="${API_KEY:-${TOKENCLOUD_API_KEY:-sk-RPo8Q8Lf9_SKoNMSjo5DNA}}"
API_BASE="${VEO_API_BASE:-https://llm.tokencloud.ai}"
CURL_OPTS="${CURL_OPTS:---connect-timeout 30 --max-time 120}"
CURL_DOWNLOAD_OPTS="${CURL_DOWNLOAD_OPTS:---connect-timeout 30 --max-time 300}"

# 工作目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
WORKSPACE="${SCRIPT_DIR}/../workspace"
