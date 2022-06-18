#!/bin/bash
pushd /home/plutonium/ >/dev/null

function usage() {
    echo -e "Usage: $0 [Server] [Command]\n"
}

function listServers() {
    echo "Available servers:"
    for f in servers/*.conf; do
        echo "    $(basename $f .conf)"
    done
}

function listCommands() {
    echo "Available commands:"
    echo "    start"
    echo "    stop"
    echo "    restart"
}

if [ -z "$1" ]; then
    usage
    echo "No server specified."
    listServers
    exit
fi

if [ ! -f servers/$1.conf ]; then
    echo "Server $1 not found."
    listServers
    exit
fi

SERVERNAME=$1

if [ -z "$2" ]; then
    usage
    echo "No command specified."
    listCommands
    exit
fi

if [ "$2" != "start" ] && [ "$2" != "stop" ] && [ "$2" != "restart" ] && [ "$2" != "update" ] && [ "$2" != "command" ]; then
    usage
    listCommands
    exit
fi

COMMAND=$2

if [ "$COMMAND" = "command" ]; then
    GAMECOMMAND=$3
fi

function start() {
    if ! screen -list | grep -q "$NAME"; then
        echo "Starting server $SERVERNAME..."
        pushd $PLUTONIUM >/dev/null
        screen -dmS $NAME wine bin/plutonium-bootstrapper-win32.exe $GAME "$GAMEFILES" $FLAGS +set key "$KEY" +set sv_config $CONFIG +net_port $PORT
        popd >/dev/null
    else
        echo "Server $SERVERNAME is already running."
    fi
}

function stop() {
    echo "Stopping $SERVERNAME.."
    gamecommand "quit"
    screen -S $NAME -X quit
    echo "$SERVERNAME stopped"
}

function restart() {
    stop
    sleep 10
    start
}

function update() {
    plutonium-updater -fsd $PLUTONIUM --no-backup
}

function gamecommand() {
    screen -S $NAME -p 0 -X stuff "$1^M"
}

source servers/$1.conf

if [ "$ENABLED" = false ]; then
    echo "Server $SERVERNAME is disabled"
    exit
fi

case "$COMMAND" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    update)
        update
        ;;
    command)
        gamecommand "$GAMECOMMAND"
        ;;
    *)
        usage
        listCommands
        ;;
esac

popd >/dev/null
