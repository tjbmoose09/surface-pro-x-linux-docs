#!/usr/bin/env bash

set -Eeuo pipefail

SPX_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export SPX_REPO_ROOT

if [[ -f "${SPX_REPO_ROOT}/config/project.env" ]]; then
  # shellcheck source=/dev/null
  source "${SPX_REPO_ROOT}/config/project.env"
fi

if [[ -f "${SPX_REPO_ROOT}/config/sources.env" ]]; then
  # shellcheck source=/dev/null
  source "${SPX_REPO_ROOT}/config/sources.env"
fi

info() {
  printf '[spx] %s\n' "$*"
}

warn() {
  printf '[spx] warning: %s\n' "$*" >&2
}

die() {
  printf '[spx] error: %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_cmd() {
  have_cmd "$1" || die "missing required command: $1"
}

ensure_dir() {
  mkdir -p "$@"
}

abs_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd)
  else
    local dir
    dir="$(dirname "$path")"
    local base
    base="$(basename "$path")"
    (cd "$dir" && printf '%s/%s\n' "$(pwd)" "$base")
  fi
}

detect_container_engine() {
  if [[ -n "${CONTAINER_ENGINE:-}" ]]; then
    printf '%s\n' "$CONTAINER_ENGINE"
  elif have_cmd podman; then
    printf '%s\n' podman
  elif have_cmd docker; then
    printf '%s\n' docker
  else
    return 1
  fi
}

clone_or_update() {
  local name="$1"
  local url="$2"
  local ref="$3"
  local dest="${4:-${SPX_SRC_DIR}/${name}}"

  need_cmd git
  ensure_dir "$(dirname "$dest")"

  if [[ -d "${dest}/.git" ]]; then
    info "Updating ${name} in ${dest}"
    git -C "$dest" remote set-url origin "$url"
    git -C "$dest" fetch --tags origin
  else
    info "Cloning ${name} from ${url}"
    git clone "$url" "$dest"
  fi

  if [[ -n "$ref" ]]; then
    git -C "$dest" checkout "$ref"
  fi

  if [[ -f "${dest}/.gitmodules" ]]; then
    git -C "$dest" submodule update --init --recursive
  fi
}

git_head() {
  local repo_dir="$1"
  git -C "$repo_dir" rev-parse HEAD
}

run_logged() {
  local log_file="$1"
  shift
  ensure_dir "$(dirname "$log_file")"
  info "Logging to ${log_file}"
  "$@" 2>&1 | tee "$log_file"
}

repo_path_for() {
  local name="$1"
  printf '%s/%s\n' "$SPX_SRC_DIR" "$name"
}
