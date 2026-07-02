# Documentacion Parte 4 - Virtualizacion

## Objetivo

La solucion empaqueta las aplicaciones de las partes 1, 2 y 3 en contenedores Docker independientes, y agrega un contenedor `manager` como unico punto de entrada operativo.

El sistema final queda compuesto por cuatro contenedores persistentes:

- `ej1`: runner Bash para la gestion de inventario del paddock.
- `ej2`: runner C para el ejercicio con hilos POSIX.
- `ej3`: runner ADA para el ejercicio con tasks.
- `manager`: contenedor de administracion, acceso SSH y panel web HTTP.

Ademas, Compose ejecuta un servicio one-shot `ssh-init` antes de levantar los contenedores persistentes. Ese servicio genera las claves SSH locales en volumenes Docker y termina.

El stack completo se levanta con:

```bash
docker compose up --build
```

El panel web queda disponible en:

```text
http://localhost:8080
```

No se usa HTTPS. La interfaz es servida por nginx.

## Arquitectura

Los runners no publican puertos al host. Solo exponen SSH dentro de la red interna de Docker Compose.

El manager es el unico contenedor accesible desde la maquina host, mediante el puerto:

```text
localhost:8080 -> manager:8080
```

La comunicacion operativa se realiza asi:

```text
Host
  -> docker compose exec manager
      -> ssh ej1 / ej2 / ej3
          -> ejecucion de la aplicacion dentro del runner
```

Esto cumple el requisito funcional de ejecutar las aplicaciones desde el manager via SSH hacia el runner correspondiente.

## Servicios

### ej1 - Runner Bash

Contiene la solucion de la parte 1:

- `paddock_manager_fixed.sh`
- `inventario_f1.csv`
- directorio `mercaderia/` con manifiestos por escuderia

El CSV contiene 10 productos por cada una de las 11 escuderias usadas en el inventario. Los manifiestos se guardan como archivos `.txt`.

Ejemplo de ejecucion desde el manager:

```bash
ssh ej1 'cd /app && ./paddock_manager_fixed.sh buscar "Gorra Edicion Especial Monza"'
```

El runner `ej1` no usa filesystem principal de solo lectura porque la aplicacion puede modificar datos: agregar productos, borrar manifiestos y actualizar el inventario.

### ej2 - Runner C

Contiene el binario del ejercicio en C, compilado durante el build con una etapa builder.

El archivo fuente se compila dentro de una imagen `gcc`, y la imagen final solo conserva lo necesario para ejecutar el programa y el servidor SSH.

El comando de ejecucion desde el manager es:

```bash
ssh ej2 'cd /app && ./parte2_code'
```

El ejecutable visible `/app/parte2_code` es un wrapper generado en el Dockerfile. Internamente llama al binario real con `stdbuf`:

```bash
stdbuf -oL -eL /app/parte2_code.bin
```

Esto fuerza salida por linea en `stdout` y `stderr`. Es necesario porque al ejecutar programas C por SSH y Docker, la salida puede quedar bufferizada y parecer que el programa no empezo, aunque este corriendo.

### ej3 - Runner ADA

Contiene el binario ADA compilado durante el build.

Se usa una etapa builder con `gnat` y una imagen final mas reducida con `libgnat-12` y `openssh-server`.

El juego requiere una terminal interactiva real para leer teclas sin esperar Enter. Por eso se fuerza TTY desde el manager:

```bash
ssh -tt ej3 'cd /app && ./main'
```

Tambien existe el helper:

```bash
run-ej3
```

Para probarlo desde el host:

```bash
docker compose exec manager run-ej3
```

### manager

El manager cumple dos responsabilidades:

1. Acceso SSH a los runners.
2. Panel web de monitoreo.

El manager tiene:

- `openssh-client`, para conectarse a `ej1`, `ej2` y `ej3`.
- `nginx`, para servir la UI en HTTP.
- `python3`, para recolectar metricas reales desde Docker.

El manager expone el puerto `8080` al host. Ningun runner expone puertos al host.

## Acceso SSH

Los runners ejecutan `sshd` en el puerto interno `2222`.

Se usa el puerto `2222` porque los runners corren como usuario no root. Un proceso no root no puede abrir puertos privilegiados como el `22` sin capabilities adicionales.

La configuracion SSH del manager define:

```sshconfig
Host ej1 ej2 ej3
    User runner
    Port 2222
    IdentityFile /tmp/manager_id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    RequestTTY force
    LogLevel ERROR
```

Por eso se puede ejecutar:

```bash
ssh ej2 'cd /app && ./parte2_code'
```

sin especificar usuario ni puerto.

## Claves SSH

Las claves SSH no se entregan en el repositorio. Se generan automaticamente al ejecutar:

```bash
docker compose up --build
```

El servicio `ssh-init` crea una clave ED25519 en volumenes Docker locales:

```text
ssh_private
ssh_authorized
```

Uso de cada volumen:

- `ssh_private`: contiene `id_ed25519` e `id_ed25519.pub`; se monta solo en el manager y en modo solo lectura.
- `ssh_authorized`: contiene `authorized_keys`; se monta en los runners y en modo solo lectura.

De esta forma, cada maquina que levanta el proyecto obtiene sus propias claves y la clave privada no queda versionada ni copiada dentro de los runners.

Para forzar una regeneracion completa de claves, se pueden borrar los volumenes del proyecto:

```bash
docker compose down -v
docker compose up --build
```

## Panel web

La UI se sirve con nginx desde el manager.

El archivo principal es:

```text
manager/index.html
```

La UI consulta periodicamente:

```text
/status.json
```

Ese archivo es generado por:

```text
manager/monitor.py
```

El monitor consulta la API local de Docker a traves de:

```text
/var/run/docker.sock
```

El socket se monta en el manager en modo solo lectura:

```yaml
/var/run/docker.sock:/var/run/docker.sock:ro
```

La UI muestra:

- estado de cada contenedor
- runners activos
- uso de CPU
- uso de memoria
- trafico de red recibido y enviado
- hora de ultima actualizacion

## Seguridad y eficiencia

La consigna pide minimizar superficie y vulnerabilidades. La configuracion final aplica varias medidas.

### Usuario no root

Los runners `ej1`, `ej2` y `ej3` ejecutan su proceso principal como usuario:

```text
runner
```

El manager ejecuta su proceso principal como:

```text
manager
```

Esto evita que los procesos principales corran como root.

### SSH endurecido

Cada runner usa una configuracion SSH propia con:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile /home/runner/.ssh/authorized_keys
AllowUsers runner
UsePAM no
```

Esto implica:

- no se permite login como root
- no se permite login por contrasena
- solo se permite autenticacion por clave publica
- solo el usuario `runner` puede conectarse

Tambien se usa `StrictModes no` para evitar problemas con permisos de archivos montados desde Windows mediante bind mounts.

### Capabilities minimas

En Docker Compose se usa:

```yaml
cap_drop:
  - ALL
```

Esto quita las Linux capabilities por defecto. Es una medida de reduccion de privilegios.

Los runners no agregan capabilities adicionales.

### Sin escalada de privilegios

Todos los servicios usan:

```yaml
security_opt:
  - no-new-privileges:true
```

Esto impide que procesos dentro del contenedor ganen privilegios adicionales mediante mecanismos como binarios `setuid`.

### Filesystem de solo lectura

`ej2` y `ej3` usan:

```yaml
read_only: true
```

Esto hace que el filesystem principal del contenedor sea de solo lectura.

Tambien se monta:

```yaml
tmpfs:
  - /tmp
```

`/tmp` queda disponible como espacio temporal en memoria.

`ej1` no usa `read_only: true` porque la aplicacion Bash necesita modificar archivos de datos, como `inventario_f1.csv` y los manifiestos de `mercaderia/`.

El manager tampoco usa `read_only: true` porque genera dinamicamente `status.json` para la UI.

### Puertos minimos

Los runners solo exponen SSH dentro de la red Docker:

```text
2222/tcp
```

No publican puertos hacia el host.

El manager publica un unico puerto:

```text
8080:8080
```

### Imagenes base

Se usan imagenes `debian:bookworm-slim` para reducir el contenido de la imagen final.

En `ej2` y `ej3` se usa build multi-stage:

- etapa builder con compiladores (`gcc` o `gnat`)
- etapa final con solo runtime y SSH

Esto evita llevar compiladores innecesarios a la imagen final.

## Comandos utiles

Levantar todo el stack:

```bash
docker compose up --build
```

Ver estado de contenedores:

```bash
docker compose ps
```

Ejecutar Bash:

```bash
docker compose exec manager ssh ej1 'cd /app && ./paddock_manager_fixed.sh buscar "Gorra Edicion Especial Monza"'
```

Ejecutar C:

```bash
docker compose exec manager ssh ej2 'cd /app && ./parte2_code'
```

Ejecutar ADA:

```bash
docker compose exec manager run-ej3
```

Consultar metricas desde el host:

```bash
curl http://localhost:8080/status.json
```

## Puntos a justificar en el informe

Hay dos decisiones importantes que conviene explicar en la defensa:

1. `ej1` no usa filesystem de solo lectura porque la aplicacion gestiona datos modificables.
2. El manager monta el Docker socket en modo solo lectura para poder obtener metricas reales de contenedores sin agregar un quinto contenedor.

El uso del socket de Docker es una decision funcional para cumplir el monitoreo real pedido por la letra. Aun asi, debe mencionarse como una superficie sensible y limitarse a consultas de estado y metricas.
