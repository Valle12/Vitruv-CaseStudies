#!/usr/bin/env bash

CONFIGS_RELATIVE_PATH="reactions/preprocessor/src/main/resources/configs"

# Maven runs on the host JVM, which on Windows does not understand the MSYS
# "/c/..." spelling this shell hands out.
to_host_path() {
  if command -v cygpath > /dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s' "$1"
  fi
}

dsls_configs_dir() {
  local repository_root candidate
  repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [ -n "${UMLJAVA_CFG_DIR:-}" ]; then
    if [ ! -d "$UMLJAVA_CFG_DIR" ]; then
      echo "UMLJAVA_CFG_DIR is set to $UMLJAVA_CFG_DIR, which does not exist" >&2
      return 1
    fi
    (cd "$UMLJAVA_CFG_DIR" && pwd)
    return 0
  fi

  for candidate in \
      "${VITRUV_DSLS_HOME:-}" \
      "$repository_root/../Vitruv-DSLs" \
      "$repository_root/../../Vitruv-DSLs" \
      "$HOME/IdeaProjects/Vitruv-DSLs" \
      "$HOME/projects/Vitruv-DSLs"; do
    [ -n "$candidate" ] || continue
    if [ -d "$candidate/$CONFIGS_RELATIVE_PATH" ]; then
      (cd "$candidate/$CONFIGS_RELATIVE_PATH" && pwd)
      return 0
    fi
  done

  echo "Could not find the Vitruv-DSLs checkout holding $CONFIGS_RELATIVE_PATH." >&2
  echo "Set VITRUV_DSLS_HOME to the checkout, or UMLJAVA_CFG_DIR to the configs folder." >&2
  return 1
}

config_reactions_dir() {
  local number="$1" configs reactions
  configs="$(dsls_configs_dir)" || return 1
  reactions="$configs/config${number}-reactions"
  if [ ! -d "$reactions" ]; then
    echo "config${number}-reactions is missing under $configs." >&2
    echo "Generate it in the Vitruv-DSLs checkout: reactions/preprocessor/preprocess-configs $number" >&2
    return 1
  fi

  to_host_path "$reactions"
}
