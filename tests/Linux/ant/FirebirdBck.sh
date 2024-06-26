# Copyright (c) [2024] [EMMANUEL T. PEIXOTO]
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
# page official of project https://github.com/irmaodejesus/SYSADMIN.FirebirdBck


#!/usr/bin/env bash

# Log file name and configuration file defined by environment variables
log_file="${LOG_FILE:-/var/log/log.FirebirdBck}"
CONFIG_FILE="${CONFIG_FILE:-/etc/firebirdbck/FirebirdBck.conf}"

CONFIG_NOT_FOUND_MSG=" Config File $CONFIG_FILE Not Found!"
EMPTY_VAR_MSG=" The variable '%s' is empty."
MSG_NO_ROOT=" This script must be run as root"
L_ERROR="ERROR "
L_INFO="INFO "
L_SCES="SUCCESS "

#  Logging Functions
log_message() {
    level="$1"
    message="$2"
    echo "$(date +"%Y-%m-%d %T") - $level - $message" >> "$log_file"
}

log_message  "$L_INFO" " ---> EXEC FirebirdBck.sh"

# Superuser Verification
if [ "$EUID" -ne 0 ]; then
    log_message "$L_ERRO" "$MSG_NO_ROOT"
    exit 1
fi

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    log_message "$L_ERRO" "$CONFIG_NOT_FOUND_MSG"
    exit 1
fi

# Upload the configuration file
source "$CONFIG_FILE"

# Function to test if a variable is empty
test_empty_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    if [ -z "$var_value" ]; then
        log_message "$L_ERRO" "$(printf "$EMPTY_VAR_MSG" "$var_name")"
        exit 1
    fi
}

test_empty_var "MOUNT_POINT"
test_empty_var "FOLDER_BKP_LOCAL"
test_empty_var "DATABASE_0"

# Function to call the scripts
call_script() {
    # Calls the passed script as an argument
    cd /sbin
    ./"$1"

    # Verifies that the script has finished successfully
    if [ $? -eq 0 ]; then
        log_message "$L_SCES" " $1" 
    else
        log_message "$L_ERRO" " $1"
        exit 1  # Exits the script if one of the scripts fails
    fi
}

msg_inicio

# Tamanho mínimo desejado em bytes (100 GB = 107374182400 bytes)
tamanho_minimo=100651956

# Obtém o tamanho do sistema de arquivos montado em bytes
tamanho=$(df --output=avail "$FOLDER_BKP_LOCAL" | tail -n 1)

# Verifica se o tamanho é maior que o mínimo desejado
if [ "$tamanho" -gt "$tamanho_minimo" ]; then
    log_message "O volume montado em $FOLDER_BKP_LOCAL é maior que 100 GB."
    # Chama os quatro scripts
    log_message "Fazendo rotation local."
    chamar_script FirebirdBckDYLocRot.sh
    log_message "parando o firebird."
    chamar_script FirebirdBckCtrSVC.sh stop
    log_message "nciciando backup DB"
    chamar_script FirebirdBckDB.sh $DATABASE_0
    log_message "inciando o servico do firebird."
    chamar_script FirebirdBckCtrSVC.sh start
    log_message "Montando NFS"
    chamar_script FirebirdBckNFSMount.sh mount
    log_message "inciando o envio do backup."
    chamar_script FirebirdBckDYSend.sh
    log_message "Desmontando NFS."
    chamar_script FirebirdBckNFSMount.sh umount
    log_message "Todos os scripts foram executados com sucesso."
    msg_termino
    exit 0
    #exit 0  # Sai do script, já que o volume é grande o suficiente
else
    log_message "O volume montado em $FOLDER_BKP_LOCAL não atende ao tamanho mínimo desejado de 100 GB."
    exit 1  # Sai do script, já que o volume não é grande o suficiente
fi

# Control Logic
case "$1" in
    mo_rotation)
        log_message "$L_INFO" "$START_MSG"

        ;;
    wk_rotation)
        log_message "$L_INFO" "$START_MSG1"
        ;;
    send_nfs)
        log_message "$L_INFO" "$START_MSG1"
        ;;
    send_sftp)
        log_message "$L_INFO" "$START_MSG1"
        ;;        
    restory_nfs)
        log_message "$L_INFO" "$START_MSG1"
        ;;     
    Setting)
        log_message "$L_INFO" "$START_MSG1"
        ;;                   
    *)
        log_message "$L_ERRO" " --> Use: $0 mount|umount "
        show_help
        ;;
esac    

# case um unico banco banco nome

# case semnal totaion
# case daiario no cron sem envio
# case diario no cron envio sftp
# case diario no cron envio scp
