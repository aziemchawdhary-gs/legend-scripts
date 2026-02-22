#!/usr/bin/env bash
# build-legend.sh -- Build the Legend stack in dependency order with version management.
#
# Projects (build order): legend-pure -> legend-shared -> legend-engine -> legend-sdlc
# Default version: $USER-SNAPSHOT
# Default Maven flags: -DskipTests -T2

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration -- edit these variables to add/reorder projects or properties
# ---------------------------------------------------------------------------
ROOTLOC="$HOME/pure"
PROJECTS=(legend-pure legend-shared legend-engine legend-sdlc)
DEFAULT_VERSION="${USER}-SNAPSHOT"
DEFAULT_MAVEN_ARGS="-DskipTests -T2"
LOG_PREFIX="[build-legend]"

# Property update matrix.
# Key:   "<built-project>:<downstream-project>"
# Value: the Maven property name to update in the downstream project.
declare -A PROPERTY_MAP=(
    ["legend-pure:legend-engine"]="legend.pure.version"
    ["legend-pure:legend-sdlc"]="legend.pure.version"
    ["legend-shared:legend-engine"]="legend.shared.version"
    ["legend-shared:legend-sdlc"]="legend.shared.version"
    ["legend-engine:legend-sdlc"]="legend.engine.version"
)

# ---------------------------------------------------------------------------
# State -- populated by argument parsing
# ---------------------------------------------------------------------------
VERSION="$DEFAULT_VERSION"
EXTRA_MAVEN_ARGS=""
DRY_RUN=false

declare -A SKIP_PROJECT
declare -A PROJECT_DIR
for p in "${PROJECTS[@]}"; do
    SKIP_PROJECT["$p"]=false
    PROJECT_DIR["$p"]="$ROOTLOC/$p"
done

USING_SKIP_FLAGS=false
USING_ONLY_FLAG=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "$LOG_PREFIX $*"; }
logts() { echo "$LOG_PREFIX [$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "$LOG_PREFIX WARNING: $*" >&2; }
die()  { echo "$LOG_PREFIX ERROR: $*" >&2; exit 1; }

# Short name helper: "legend-pure" -> "pure"
short_name() { echo "${1#legend-}"; }

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send -u CRITICAL "$1" || true
    fi
}

run_cmd() {
    # Execute a command, or print it if --dry-run is active.
    if $DRY_RUN; then
        log "[dry-run] $*"
        return 0
    fi
    "$@"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the Legend stack (legend-pure, legend-shared, legend-engine, legend-sdlc)
in dependency order with automatic snapshot version management.

Options:
  --version <ver>       Set snapshot version (default: $DEFAULT_VERSION)
  --skip-pure           Skip legend-pure
  --skip-shared         Skip legend-shared
  --skip-engine         Skip legend-engine
  --skip-sdlc           Skip legend-sdlc
  --only <project...>   Build ONLY the listed projects (short names: pure, shared,
                        engine, sdlc). Mutually exclusive with --skip-* flags.
  --maven-args "<args>" Append extra Maven arguments (default flags always
                        included: $DEFAULT_MAVEN_ARGS)
  --pure-path <path>    Override legend-pure directory   (default: $ROOTLOC/legend-pure)
  --shared-path <path>  Override legend-shared directory (default: $ROOTLOC/legend-shared)
  --engine-path <path>  Override legend-engine directory (default: $ROOTLOC/legend-engine)
  --sdlc-path <path>    Override legend-sdlc directory   (default: $ROOTLOC/legend-sdlc)
  --dry-run             Print commands without executing them
  -h, --help            Show this help message and exit

Examples:
  $(basename "$0")                               # full stack, \$USER-SNAPSHOT
  $(basename "$0") --version 1.0.0-SNAPSHOT      # full stack, custom version
  $(basename "$0") --skip-pure --skip-shared      # engine + sdlc only
  $(basename "$0") --only pure engine             # pure + engine only
  $(basename "$0") --skip-sdlc --maven-args "-pl legend-engine-core -am"
  $(basename "$0") --dry-run                      # preview without building
  $(basename "$0") --engine-path ~/pure/legend-engine-worktree  # use a worktree
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            --version)
                [[ $# -ge 2 ]] || die "--version requires a value"
                VERSION="$2"
                shift 2
                ;;
            --skip-pure)
                USING_SKIP_FLAGS=true
                SKIP_PROJECT["legend-pure"]=true
                shift
                ;;
            --skip-shared)
                USING_SKIP_FLAGS=true
                SKIP_PROJECT["legend-shared"]=true
                shift
                ;;
            --skip-engine)
                USING_SKIP_FLAGS=true
                SKIP_PROJECT["legend-engine"]=true
                shift
                ;;
            --skip-sdlc)
                USING_SKIP_FLAGS=true
                SKIP_PROJECT["legend-sdlc"]=true
                shift
                ;;
            --only)
                USING_ONLY_FLAG=true
                shift
                # Consume all following non-flag arguments as project names
                while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
                    local proj="legend-$1"
                    local found=false
                    for p in "${PROJECTS[@]}"; do
                        if [[ "$p" == "$proj" ]]; then
                            found=true
                            break
                        fi
                    done
                    $found || die "Unknown project for --only: $1 (valid: pure, shared, engine, sdlc)"
                    # Mark this project as NOT skipped (we invert below)
                    SKIP_PROJECT["$proj"]="only"
                    shift
                done
                ;;
            --maven-args)
                [[ $# -ge 2 ]] || die "--maven-args requires a value"
                EXTRA_MAVEN_ARGS="$2"
                shift 2
                ;;
            --pure-path)
                [[ $# -ge 2 ]] || die "--pure-path requires a value"
                PROJECT_DIR["legend-pure"]="$2"
                shift 2
                ;;
            --shared-path)
                [[ $# -ge 2 ]] || die "--shared-path requires a value"
                PROJECT_DIR["legend-shared"]="$2"
                shift 2
                ;;
            --engine-path)
                [[ $# -ge 2 ]] || die "--engine-path requires a value"
                PROJECT_DIR["legend-engine"]="$2"
                shift 2
                ;;
            --sdlc-path)
                [[ $# -ge 2 ]] || die "--sdlc-path requires a value"
                PROJECT_DIR["legend-sdlc"]="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                die "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done

    # --only and --skip-* are mutually exclusive
    if $USING_ONLY_FLAG && $USING_SKIP_FLAGS; then
        die "--only and --skip-* flags are mutually exclusive"
    fi

    # If --only was used, invert: skip everything that was NOT marked "only"
    if $USING_ONLY_FLAG; then
        for p in "${PROJECTS[@]}"; do
            if [[ "${SKIP_PROJECT[$p]}" == "only" ]]; then
                SKIP_PROJECT["$p"]=false
            else
                SKIP_PROJECT["$p"]=true
            fi
        done
    fi
}

# ---------------------------------------------------------------------------
# Build helpers
# ---------------------------------------------------------------------------
set_project_version() {
    local project="$1"
    local project_dir="${PROJECT_DIR[$project]}"

    log "Setting $project version to $VERSION (in $project_dir)"
    run_cmd mvn -f "$project_dir/pom.xml" versions:set \
        -DnewVersion="$VERSION" \
        -DgenerateBackupPoms=false
}

update_downstream_property() {
    local downstream="$1"
    local property="$2"
    local downstream_dir="${PROJECT_DIR[$downstream]}"

    log "Updating $downstream property $property to $VERSION (in $downstream_dir)"
    run_cmd mvn -f "$downstream_dir/pom.xml" versions:set-property \
        -Dproperty="$property" \
        -DnewVersion="$VERSION" \
        -DgenerateBackupPoms=false
}

propagate_version() {
    # For the just-built project, update dependency properties in non-skipped
    # downstream projects according to PROPERTY_MAP.
    local built_project="$1"

    for key in "${!PROPERTY_MAP[@]}"; do
        # key format: "built:downstream"
        local src="${key%%:*}"
        local dst="${key##*:}"
        local prop="${PROPERTY_MAP[$key]}"

        if [[ "$src" == "$built_project" ]] && [[ "${SKIP_PROJECT[$dst]}" == "false" ]]; then
            update_downstream_property "$dst" "$prop"
        fi
    done
}

build_project() {
    local project="$1"
    local project_dir="${PROJECT_DIR[$project]}"

    # shellcheck disable=SC2086
    logts "Building $project ($project_dir) ..."
    if ! run_cmd mvn -f "$project_dir/pom.xml" clean install $DEFAULT_MAVEN_ARGS $EXTRA_MAVEN_ARGS; then
        die "Build FAILED for $project"
    fi
    logts "$project build completed"
    notify "$project build completed!"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"

    log "=== Legend Stack Build ==="
    log "Version:     $VERSION"
    log "Maven args:  $DEFAULT_MAVEN_ARGS $EXTRA_MAVEN_ARGS"
    log "Dry run:     $DRY_RUN"
    log "Paths:"
    for p in "${PROJECTS[@]}"; do
        if [[ "${SKIP_PROJECT[$p]}" == "false" ]]; then
            local default_dir="$ROOTLOC/$p"
            if [[ "${PROJECT_DIR[$p]}" != "$default_dir" ]]; then
                log "  $p: ${PROJECT_DIR[$p]} (override)"
            else
                log "  $p: ${PROJECT_DIR[$p]}"
            fi
        fi
    done

    # Summarize what will be built
    local built_list=()
    local skipped_list=()
    for p in "${PROJECTS[@]}"; do
        if [[ "${SKIP_PROJECT[$p]}" == "false" ]]; then
            built_list+=("$p")
        else
            skipped_list+=("$p")
        fi
    done
    log "Build:       ${built_list[*]:-<none>}"
    [[ ${#skipped_list[@]} -gt 0 ]] && log "Skip:        ${skipped_list[*]}"
    log ""

    # Warn about stale downstream versions when skip flags are used
    for p in "${PROJECTS[@]}"; do
        if [[ "${SKIP_PROJECT[$p]}" == "true" ]]; then
            for key in "${!PROPERTY_MAP[@]}"; do
                local src="${key%%:*}"
                local dst="${key##*:}"
                if [[ "$src" == "$p" ]] && [[ "${SKIP_PROJECT[$dst]}" == "false" ]]; then
                    warn "Skipping $p -- $dst will retain its existing ${PROPERTY_MAP[$key]} (potentially stale)"
                fi
            done
        fi
    done

    # Check that project directories exist
    for p in "${built_list[@]}"; do
        if [[ ! -d "${PROJECT_DIR[$p]}" ]]; then
            warn "Directory ${PROJECT_DIR[$p]} does not exist -- skipping $p"
            SKIP_PROJECT["$p"]=true
        fi
    done

    # Build loop
    local overall_start
    overall_start=$(date +%s)

    for project in "${PROJECTS[@]}"; do
        if [[ "${SKIP_PROJECT[$project]}" != "false" ]]; then
            continue
        fi

        log "------------------------------------------------------------"
        logts ">>> Starting $project"

        local step_start
        step_start=$(date +%s)

        # 1. Set project's own version
        set_project_version "$project"

        # 2. Propagate version to non-skipped downstream projects
        propagate_version "$project"

        # 3. Build
        build_project "$project"

        local step_end
        step_end=$(date +%s)
        log "$project finished in $(( step_end - step_start ))s"
        log ""
    done

    local overall_end
    overall_end=$(date +%s)
    log "============================================================"
    logts "All builds completed in $(( overall_end - overall_start ))s"
    notify "Legend stack build completed! (${built_list[*]})"
}

main "$@"
