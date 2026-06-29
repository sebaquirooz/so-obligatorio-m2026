#!/bin/bash
# paddock_manager.sh - V1.0 (Legacy)
# Uso: ./paddock_manager.sh [accion] [parametros...]
set -o nounset
set -o pipefail

ACCION="${1:-}"
PARAMETRO="${*:2}"

ARCHIVO_CSV="inventario_f1.csv"
DIR_MERCADERIA="./mercaderia"

if [ -z "$ACCION" ]; then
    echo "Error: Debes especificar una accion (ingresar, buscar, vender, descatalogar)."
    exit 1
fi

if [ ! -f "$ARCHIVO_CSV" ]; then
    echo "Error: no existe $ARCHIVO_CSV."
    exit 1
fi

if [ ! -d "$DIR_MERCADERIA" ]; then
    echo "Error: no existe $DIR_MERCADERIA."
    exit 1
fi

case "$ACCION" in
    buscar)
        if [ -z "$PARAMETRO" ]; then
            echo "Error: Debes especificar un producto o texto a buscar."
            exit 1
        fi

        echo "Buscando '$PARAMETRO' en el inventario..."
        grep -- "$PARAMETRO" "$ARCHIVO_CSV"
        ;;

    descatalogar)
        if [ -z "$PARAMETRO" ]; then
            echo "Error: Debes especificar una escuderia."
            exit 1
        fi

        echo "Descatalogando productos y manifiestos de la escuderia: $PARAMETRO"
        find "$DIR_MERCADERIA" -maxdepth 1 -type f -name "${PARAMETRO}*.txt" -delete
        sed -i.bak "\|,$PARAMETRO,|d" "$ARCHIVO_CSV"
        rm -f -- "${ARCHIVO_CSV}.bak"
        echo "Operacion finalizada."
        ;;

    ingresar)
        if [ -z "$PARAMETRO" ]; then
            echo "Error: Debes especificar la linea CSV del producto."
            exit 1
        fi

        echo "Ingresando nuevo producto..."
        printf '%s\n' "$PARAMETRO" >> "$ARCHIVO_CSV"
        echo "Producto ingresado."
        ;;

    vender)
        echo "Vendiendo 1 unidad del ID: $PARAMETRO"
        echo "Funcion en mantenimiento..."
        ;;

    *)
        echo "Accion no reconocida."
        exit 1
        ;;
esac
