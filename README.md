# 📂 Documentación - Gestor de Archivos Assembly

Este documento describe en detalle cada sección, rutina y ejemplos de uso del código ensamblador para un gestor de archivos en NASM que permite crear, leer, sobreescribir, añadir y eliminar archivos de texto, tanto en modo interactivo como desde la línea de comandos (CMD y PowerShell).

---

## 📋 Contenido
- [Declaraciones Externas](#1-declaraciones-externas)
- [Sección .data](#2-sección-data)
- [Sección .bss](#3-sección-bss)
- [Punto de Entrada y Flujo General](#4-punto-de-entrada-main-y-flujo-general)
- [Modo Interactivo](#5-modo-interactivo-modointeractivo)
- [Modo por Argumentos](#6-modo-por-argumentos)
- [Procesar Comando](#7-procesar-comando-procesarcomando)
- [Archivo No Existe](#8-archivo-no-existe-archivonexiste)
- [Flujo de Creación](#9-flujo-de-creación-preguntarcrear--pedirnuevonombre)
- [Manejo de Existente](#10-manejo-de-existente-manejarexistente)
- [Rutinas de Operación](#11-rutinas-de-operación)
- [Salida y Limpieza](#12-salida-y-limpieza-salir)
- [Ejecución desde Línea de Comandos](#13-ejecución-desde-línea-de-comandos)
- [Conclusión](#conclusión)

---

### 1. 🔗 Declaraciones Externas
```nasm
extern _fopen, _fclose, _fgets, _fprintf
extern _printf, _scanf, _sscanf, _remove
extern _exit, _gets, _getchar
extern _strlen, _strcpy, _strcat, _strstr
```

| Función | Descripción |
|---------|-------------|
| **_fopen, _fclose, _fgets, _fprintf** | Funciones de la biblioteca C para manejo de archivos |
| **_printf, _scanf, _sscanf** | Para entrada/salida por consola |
| **_remove** | Elimina un archivo del sistema |
| **_gets, _getchar** | Lectura de cadenas y caracteres desde stdin |
| **_strlen, _strcpy, _strcat, _strstr** | Manipulación de cadenas |

---

### 2. 💾 Sección .data
Define constantes, formatos de impresión y mensajes:

#### 📝 Formatos
- `intFormat`: `%d` para enteros
- `formatString`: `%s` para cadenas
- `charFormat`: `%c` para caracteres
- `formatoSalida`: imprime cadena + salto de línea

#### 🔓 Modos de apertura
| Código | Valor | Descripción |
|--------|-------|-------------|
| `codigoEscribir` | `"w"` | Escribir/sobreescribir |
| `codigoAppend` | `"a"` | Añadir al final |
| `codigoAbrir` | `"r"` | Solo lectura |

#### 💬 Mensajes y prompts
- **Errores**: `Err1`, `Err2`, `Err3`, `msgArgumenInvalido`
- **Interacción**: `msgNoExiste`, `msgPreguntaCrear`, `msgNombreNuevo`
- **Estados**: `msgSobreescribiendo`, `msgAnhadiendo`, `msgEliminando`, `msgCreando`, `msgAbriendo`, `msgLeyendo`, `archivoCreado`
- **Prompts**: `promptNombre`, `promptAccion`, `promptLineas`, `promptTexto`

#### 📄 Extensión
- `extensionTxt` (`".txt"`)

---

### 3. 🧰 Sección .bss
Reservas de espacio:
```nasm
numeroLineas    resd    1     ; Cantidad de líneas a escribir
nombreArchivo   resb    100   ; Nombre base ingresado
nombreCompleto  resb    105   ; Nombre + ".txt"
nuevoNombre     resb    100   ; Nuevo nombre para creación
nuevoCompleto   resb    105   ; Nuevo nombre + ".txt"
accion          resb    2     ; 'c','a','e','l'
respuesta       resb    2     ; 's' o 'n'
auxLinea        resb    72    ; Lectura línea a línea
bufferLectura   resb    1024  ; Buffer genérico
inputBuffer     resb    256   ; Cadena a escribir
```

---

### 4. 🚀 Punto de Entrada (`_main`) y Flujo General
```nasm
global _main
_main:
    push ebp
    mov  ebp, esp
    push ebx, esi, edi
    mov  eax, [ebp+8]    ; argc
    mov  ebx, [ebp+12]   ; argv
    mov  dword [numeroLineas], 5
    ; Ramas según argc: 1→interactivo, 2→solo nombre, 3→nombre+acción, 4→todo
    cmp eax, 1
    je  .modoInteractivo
    cmp eax, 2
    je  .soloNombre
    cmp eax, 3
    je  .nombreYAccion
    cmp eax, 4
    je  .todosArgumentos
    jmp .argumentosInvalidos
```  

---

### 5. 💻 Modo Interactivo (`.modoInteractivo`)
1. Solicita **nombre** (`promptNombre`)
2. Solicita **acción** (`promptAccion`):
   - `l/L`: leer 📖
   - `e/E`: eliminar 🗑️
   - `c/C`: crear (sobreescribir) ✏️
   - `a/A`: añadir ➕
3. Si no es leer/eliminar, solicita **número de líneas** (`promptLineas`, default 5)
4. Salta a `.procesarComando`

---

### 6. ⌨️ Modo por Argumentos
- **`.soloNombre`** (1 arg): lectura 📖
- **`.nombreYAccion`** (2 args): nombre + acción
- **`.todosArgumentos`** (3 args): nombre + acción + líneas (valida con `sscanf`)
- **`.argumentosInvalidos`** (>3 args): muestra uso correcto ⚠️

---

### 7. ⚙️ Procesar Comando (`.procesarComando`)
1. Asegura extensión `.txt` 📄
2. Intenta abrir en modo lectura:
   - Si existe → `.manejarExistente` ✅
   - Si no → `.archivoNoExiste` ❌

---

### 8. ❓ Archivo No Existe (`.archivoNoExiste`)
- Muestra `msgNoExiste`
- Si **leer** → `.errorApertura` ❌
- Si **crear** → `.crear` ✏️
- Para **añadir**/ **eliminar** → `.preguntarCrear` ❓

---

### 9. 🆕 Flujo de Creación (`.preguntarCrear` / `.pedirNuevoNombre`)
- Pregunta, si `s/S` → fija `accion='c'` y pide nuevo nombre
- Valida extensión y existencia:
  - Si existe → selecciona acción sobre ese archivo
  - Si no → copia a `nombreCompleto` y va a `.crear`

---

### 10. 🔄 Manejo de Existente (`.manejarExistente`)
Según `accion`:
- **Leer** → `.leerArchivoExistente` 📖
- **Eliminar** → `.cerrarYEliminar` 🗑️
- **Sobreescribir** → `.cerrarYSobreescribir` ✏️
- **Crear** → `.cerrarYSoloAbrir` 🆕
- **Añadir** (por defecto) → `.anhiadir` ➕

---

### 11. 🛠️ Rutinas de Operación

#### 11.1 📖 Lectura de Archivo (`.leerArchivo`)
```nasm
.bucleLeeLin:
  _fgets(auxLinea, longLinea, ebx)
  cmp eax, 0
  je  .finLectura
  _printf(auxLinea)
  jmp .bucleLeeLin
.finLectura:
  _printf(finArchivo)
  _fclose(ebx)
  jmp salir
```

#### 11.2 ✏️ Escritura / Añadido (`.escribir`)
```nasm
; Ya abierto en "w" o "a"
push promptTexto
call _printf
add  esp, 4
push inputBuffer
call _gets
add  esp, 4
mov  edi, [numeroLineas]
.bucleEscritura:
  cmp edi, 0
  je  .cerrarArchivo
  push inputBuffer
  push formatoSalida
  push ebx
  call _fprintf
  add  esp,12
  dec  edi
  jmp  .bucleEscritura
.cerrarArchivo:
  _fclose(ebx)
  _printf(archivoCreado, nombreCompleto)
  jmp salir
```  

#### 11.3 🗑️ Eliminación de Archivo (`.eliminar`)
```nasm
_printf(msgEliminando, nombreCompleto)
_remove(nombreCompleto)
cmp eax,0
jne .errorEliminacion
_printf(formatDelete, nombreCompleto)
jmp salir
```

---

### 12. 🚪 Salida y Limpieza (`.salir`)
```nasm
pop edi
pop esi
pop ebx
mov esp, ebp
pop ebp
ret
```

---

### 13. 🖥️ Ejecución desde Línea de Comandos

#### 13.1 🔤 Comandos en CMD (Windows)
```bat
REM Leer archivo existente
C:\> gestor_archivos archivo.txt l
Leyendo contenido del archivo archivo.txt:
... (contenido) ...
--- Fin del archivo ---

REM Crear nuevo archivo (o sobreescribir si existe)
C:\> gestor_archivos nuevo.txt c 2
Ingrese el texto a escribir: Texto de ejemplo
Se escribirán 2 líneas
Se ha escrito exitosamente en el archivo nuevo.txt

REM Sobreescribir archivo existente
C:\> gestor_archivos archivo_existente.txt s 3
Ingrese el texto a escribir: Reescritura
Se escribirán 3 líneas
Se ha escrito exitosamente en el archivo archivo_existente.txt

REM Añadir al archivo existente
C:\> gestor_archivos archivo_existente.txt a 1
Ingrese el texto a escribir: Línea adicional
Se escribirán 1 líneas
Se ha escrito exitosamente en el archivo archivo_existente.txt

REM Eliminar archivo
C:\> gestor_archivos archivo_para_eliminar.txt e
Archivo archivo_para_eliminar.txt eliminado correctamente
```

#### 13.2 💠 Comandos en PowerShell
```powershell
# Leer archivo existente
PS C:\> .\gestor_archivos archivo.txt l
Leyendo contenido del archivo archivo.txt:
... (contenido) ...
--- Fin del archivo ---

# Crear nuevo archivo (o sobreescribir si existe)
PS C:\> .\gestor_archivos nuevo.txt c 2
Ingrese el texto a escribir: Texto de ejemplo
Se escribirán 2 líneas
Se ha escrito exitosamente en el archivo nuevo.txt

# Sobreescribir archivo existente
PS C:\> .\gestor_archivos archivo_existente.txt s 3
Ingrese el texto a escribir: Reescritura
Se escribirán 3 líneas
Se ha escrito exitosamente en el archivo archivo_existente.txt

# Añadir al archivo existente
PS C:\> .\gestor_archivos archivo_existente.txt a 1
Ingrese el texto a escribir: Línea adicional
Se escribirán 1 líneas
Se ha escrito exitosamente en el archivo archivo_existente.txt

# Eliminar archivo
PS C:\> .\gestor_archivos archivo_para_eliminar.txt e
Archivo archivo_para_eliminar.txt eliminado correctamente
```

---

## 🏁 Conclusión
Esta documentación cubre la estructura, secciones, etiquetas y ejemplos de uso del gestor de archivos en NASM, incluyendo interacción y ejemplos de comandos en línea de comandos (CMD y PowerShell). Puedes adaptar nombres de ejecutable y rutas según tu entorno.

---

> 💡 **Tip**: Para compilar el programa, utiliza NASM junto con un enlazador compatible con tu sistema.
