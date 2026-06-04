# Ticekt 104

El problema esta en la linea
```bash
grep $PARAMETRO $ARCHIVO_CSV
```

Al correr esa línea, como **$PARAMETRO** esta sin comillas, Bash aplica **word splitting**. Entonces el comando real queda como si fuera
```bash
grep Gorra Edicion Especial Monza inventario_f1.csv
```

O sea, intenta buscar Gorra pero interpreta a Edicion, Especial y Monza como archivos donde debe buscar, además de inventario_f1.csv. Por eso aparece el error de que Edición no existe, no que es no exista un objeto Edicion, sino que Bash interpreta que estas queriendo buscar Gorra en un archivo llamado Edicion.

La correción sería usar comillas:
```bash
grep "$PARAMETRO" "$ARCHIVO_CSV"
```

https://stackoverflow.com/questions/28958471/grepping-for-a-sentence-from-inside-a-bash-script


# Ticket 105 

El problema esta en la linea

```bash
rm $DIR_MERCADERIA/$PARAMETRO*.txt
```

El error ocurre porque la variable **$PARAMETRO** no fue validada antes de su uso.

Cuando el script se ejecuta sin argumento:

```bash
./paddock_manager.sh descatalogar
```

entonces:

```bash
$PARAMETRO=""
```

La línea se convierte en:

```bash
rm $DIR_MERCADERIA/*.txt
```
es expandido automáticamente por Bash a **todos los archivos `.txt` del directorio `/mercaderia/`**.


El comando ejecutado termina siendo equivalente a:

```bash
rm ./mercaderia/*.txt
```
