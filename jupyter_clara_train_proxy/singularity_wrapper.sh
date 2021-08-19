#!/bin/bash -e

initialize(){
    export ROOT="$(dirname "$(cd "$(dirname "$\{BASH_SOURCE[0]\}")" >/dev/null 2>&1 && pwd -P)")"
    #TMPROOT will be root mount point for all writable files in container.

    module purge
    module unload XALT/full
    module load Singularity
    export TERM="xterm"
}

parseinputs(){
    port=$1
    base_url=$2
}

bindconfs(){
    tmp_ports_conf=$(mktemp "$TMPDIR/XXX_ports.conf")
    temp_aiaa_conf=$(mktemp "$TMPDIR/XXX_aiaa.conf")
    
    #echo "Listen ${base_url}/proxy:${port}" > "$tmp_ports_conf"
    echo "Listen *:${port}" > "$tmp_ports_conf"

    cat << EOF > "$temp_aiaa_conf"
<VirtualHost *:${port}>
    DocumentRoot "/opt/nvidia/medical/aiaa/www/docs"

    WSGIDaemonProcess AIAA_V1    threads=2 python-path=/opt/nvidia/medical
    WSGIDaemonProcess AIAA_Admin threads=1 python-path=/opt/nvidia/medical
    WSGIDaemonProcess AIAA_Sess  threads=3 python-path=/opt/nvidia/medical
    WSGIDaemonProcess AIAA_Logs  threads=3 python-path=/opt/nvidia/medical
    WSGIDaemonProcess AIAA_Docs  threads=3 python-path=/opt/nvidia/medical

    # Give an alias to to start your website url with
    WSGIScriptAlias /v1 /opt/nvidia/medical/aiaa/www/api_v1.wsgi           process-group=AIAA_V1
    WSGIScriptAlias /admin /opt/nvidia/medical/aiaa/www/api_admin.wsgi     process-group=AIAA_Admin
    WSGIScriptAlias /session /opt/nvidia/medical/aiaa/www/api_session.wsgi process-group=AIAA_Sess
    WSGIScriptAlias /logs /opt/nvidia/medical/aiaa/www/api_logs.wsgi       process-group=AIAA_Logs
    WSGIScriptAlias /docs /opt/nvidia/medical/aiaa/www/api_docs.wsgi       process-group=AIAA_Docs

    <Directory /opt/nvidia/medical/aiaa>
            WSGIApplicationGroup %{GLOBAL}
            Options FollowSymLinks
            AllowOverride None
            Require all granted
    </Directory>

    RequestReadTimeout header=0 body=0

    LogLevel error
    ErrorLogFormat "[%{c}t] %M"
    ErrorLog  "|/usr/bin/rotatelogs -n 10 -L \${APACHE_LOG_DIR}/aiaa.log \${APACHE_LOG_DIR}/aiaa_apache.log 10M"

    SetEnvIf Remote_Addr "127\.0\.0\.1" dontlog
    SetEnvIf Request_URI "^/logs/(.*)" dontlog
    SetEnvIf Request_URI "^/favicon.ico" dontlog
    CustomLog \${APACHE_LOG_DIR}/access.log combined env=!dontlog
</VirtualHost>
EOF
}

main(){
    initialize
    parseinputs "$@"
    bindconfs

    sif_path="/opt/nesi/containers/clara/clara-train-sdk_v4.0.sif"
    bindpath="$HOME,/nesi/project,/nesi/nobackup,${tmp_ports_conf}:/etc/apache2/ports.conf,${temp_aiaa_conf}:/etc/apache2/sites-available/aiaa.conf"

    aiaacmd="/opt/nvidia/medical/aiaa/AIAA start --engine AIAA -w $PWD"
    smgcmd="singularity $([[ "$DEBUG" ]] && echo "shell" || echo "exec") --nv -B $bindpath $sif_path $aiaacmd"

    echo $smgcmd
    $smgcmd
}

main "$@"

