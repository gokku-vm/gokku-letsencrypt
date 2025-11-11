list_ssl_dirs() {
    local services_root="/opt/gokku/services"

    if [ -d "$services_root" ]; then
        find "$services_root" -mindepth 2 -maxdepth 2 -type d -name ssl -print0 2>/dev/null \
            | while IFS= read -r -d '' dir; do
                printf '%s\n' "$dir"
            done
    fi
}

list_ssl_services() {
    local certs_dir="/opt/gokku/plugins/letsencrypt/certs"
    local -a services=()
    local ssl_dir service_name cert_path target

    while IFS= read -r ssl_dir; do
        [ -z "$ssl_dir" ] && continue
        service_name=$(basename "$(dirname "$ssl_dir")")

        if compgen -G "$ssl_dir"/*.crt > /dev/null 2>&1; then
            while IFS= read -r -d '' cert_path; do
                [ -e "$cert_path" ] || continue
                if [ -L "$cert_path" ]; then
                    target=$(readlink "$cert_path")
                    case "$target" in
                        "$certs_dir"/*)
                            if ! printf '%s\n' "${services[@]}" | grep -Fxq "$service_name"; then
                                services+=("$service_name")
                            fi
                            break
                            ;;
                    esac
                fi
            done < <(find "$ssl_dir" -maxdepth 1 -type l -name "*.crt" -print0 2>/dev/null)
        fi
    done < <(list_ssl_dirs)

    printf '%s\n' "${services[@]}"
}