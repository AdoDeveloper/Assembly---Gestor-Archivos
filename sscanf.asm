; ------------------------------------------------------------------------
; Programa en ensamblador con manejo de archivos: crear, leer, añadir,
; sobrescribir y eliminar, con validación de existencia y entrada segura,
; y repite un texto N veces según se indique.
; ------------------------------------------------------------------------

extern  _fopen, _fclose, _fgets, _fprintf
extern  _printf, _scanf, _sscanf, _remove
extern  _exit, _gets, _getchar
extern  _strlen, _strcpy, _strcat, _strstr

section .data
    intFormat:            db "%d",0
    formatString:         db "%s",0
    charFormat:           db "%c",0
    formatoSalida:        db "%s",10,0
    codigoEscribir:       db "w",0
    codigoAppend:         db "a",0
    codigoAbrir:          db "r",0
    Err1:                 db "ERROR: el tercer argumento debe ser entero",10,0
    Err2:                 db "ERROR: el archivo no puede ser abierto",10,0
    Err3:                 db "ERROR: Uso correcto: programa [nombre_archivo] [accion(c=crear|a=anadir|e=eliminar|l=leer)] [lineas]",10,0
    msgArgumenInvalido:   db "ERROR: Argumentos invalidos. Por favor siga el formato correcto.",10,0
    msgNoExiste:          db "El archivo %s no existe.",10,0
    msgSiExiste:          db "El archivo %s ya existe. Solo se abrira sin modificar el contenido.",10,0
    msgSiExisteSobreesc:  db "El archivo %s ya existe. Se sobreescribira su contenido.",10,0
    formatDelete:         db "Archivo %s eliminado correctamente",10,0
    formatDeleteErr:      db "Error al eliminar el archivo %s",10,0
    archivoCreado:        db "Se ha escrito exitosamente en el archivo %s",10,0
    msgSobreescribiendo:  db "Sobreescribiendo archivo %s...",10,0
    msgAnhadiendo:        db "Anadiendo al archivo %s...",10,0
    msgEliminando:        db "Eliminando archivo %s...",10,0
    msgCreando:           db "Creando nuevo archivo %s...",10,0
    msgAbriendo:          db "Abriendo archivo %s sin modificarlo...",10,0
    msgLeyendo:           db "Leyendo contenido del archivo %s:",10,0
    finArchivo:           db "--- Fin del archivo ---",10,0
    msgCount:             db "Total de lineas leidas: %d",10,0
    promptNombre:         db "Ingrese el nombre del archivo: ",0
    promptAccion:         db "Ingrese la accion (s=sobreescribir, a=anadir, e=eliminar, c=crear, l=leer): ",0
    promptLineas:         db "Ingrese el numero de lineas a escribir: ",0
    promptTexto:          db "Ingrese el texto a escribir: ",0
    extensionTxt:         db ".txt",0

section .bss
    numeroLineas    resd    1
    nombreArchivo   resb    100
    nombreCompleto  resb    105
    nuevoNombre     resb    100
    nuevoCompleto   resb    105
    accion          resb    2
    respuesta       resb    2
    auxLinea        resb    72
    bufferLectura   resb    1024
    inputBuffer     resb    256
    counter         resd    1
    longLinea       EQU     72

section .text
global  _main
_main:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Leer argc y argv
    mov     eax, [ebp+8]       ; argc
    mov     ebx, [ebp+12]      ; argv

    cmp     eax, 1
    je      .modoInteractivo
    cmp     eax, 2
    je      .soloNombre
    cmp     eax, 3
    je      .nombreYAccion
    cmp     eax, 4
    je      .todosArgumentos
    jmp     .argumentosInvalidos

; ------------------------------------------------------------------------
; Modo interactivo
; ------------------------------------------------------------------------
.modoInteractivo:
    push    promptNombre
    call    _printf
    add     esp, 4
    push    nombreArchivo
    call    _gets
    add     esp, 4

    push    promptAccion
    call    _printf
    add     esp, 4
    call    _getchar
    mov     [accion], al
    call    _getchar

    cmp     byte [accion], 'l'
    je      .skipLineasI
    cmp     byte [accion], 'L'
    je      .skipLineasI
    cmp     byte [accion], 'e'
    je      .skipLineasI
    cmp     byte [accion], 'E'
    je      .skipLineasI

.askLinesI:
    push    promptLineas
    call    _printf
    add     esp, 4
    push    inputBuffer
    call    _gets
    add     esp, 4
    push    numeroLineas
    push    intFormat
    push    inputBuffer
    call    _sscanf
    add     esp, 12
    cmp     eax, 1
    jne     .askLinesI
    cmp     dword [numeroLineas], 0
    jle     .askLinesI

.skipLineasI:
    jmp     .procesarComando

; ------------------------------------------------------------------------
; Modo solo nombre (lectura)
; ------------------------------------------------------------------------
.soloNombre:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp, 8
    mov     byte [accion], 'l'
    jmp     .procesarComando

; ------------------------------------------------------------------------
; Modo nombre+acción
; ------------------------------------------------------------------------
.nombreYAccion:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp, 8
    mov     esi, [ebx+8]
    mov     al, [esi]
    mov     [accion], al

    cmp     byte [accion], 'l'
    je      .procesarComando
    cmp     byte [accion], 'L'
    je      .procesarComando
    cmp     byte [accion], 'e'
    je      .procesarComando
    cmp     byte [accion], 'E'
    je      .procesarComando
    jmp     .askLinesI

; ------------------------------------------------------------------------
; Modo todos argumentos
; ------------------------------------------------------------------------
.todosArgumentos:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp, 8
    mov     esi, [ebx+8]
    mov     al, [esi]
    mov     [accion], al

    push    numeroLineas
    push    intFormat
    push    dword [ebx+12]
    call    _sscanf
    add     esp, 12
    cmp     eax, 1
    jne     .askLinesI
    cmp     dword [numeroLineas], 0
    jle     .askLinesI
    jmp     .procesarComando

; ------------------------------------------------------------------------
; Argumentos inválidos
; ------------------------------------------------------------------------
.argumentosInvalidos:
    push    msgArgumenInvalido
    call    _printf
    add     esp, 4
    push    Err3
    call    _printf
    add     esp, 4
    jmp     .salir

; ------------------------------------------------------------------------
; Asegurar extensión .txt
; ------------------------------------------------------------------------
.procesarComando:
    push    nombreArchivo
    push    nombreCompleto
    call    _strcpy
    add     esp, 8
    push    extensionTxt
    push    nombreCompleto
    call    _strstr
    add     esp, 8
    cmp     eax, 0
    jne     .openCheck
    push    extensionTxt
    push    nombreCompleto
    call    _strcat
    add     esp, 8

.openCheck:
    push    codigoAbrir
    push    nombreCompleto
    call    _fopen
    add     esp, 8
    cmp     eax, 0
    je      .archivoNoExiste
    mov     ebx, eax
    jmp     .manejarExistente

; ------------------------------------------------------------------------
; Archivo no existe — según acción
; ------------------------------------------------------------------------
.archivoNoExiste:
    push    nombreCompleto
    push    msgNoExiste
    call    _printf
    add     esp, 8

    cmp     byte [accion], 'l'
    je      .salir
    cmp     byte [accion], 'L'
    je      .salir
    cmp     byte [accion], 'e'
    je      .salir
    cmp     byte [accion], 'E'
    je      .salir

    cmp     byte [accion], 'c'
    je      .crear
    cmp     byte [accion], 'C'
    je      .crear
    cmp     byte [accion], 's'
    je      .crear
    cmp     byte [accion], 'S'
    je      .crear
    cmp     byte [accion], 'a'
    je      .crear
    cmp     byte [accion], 'A'
    je      .crear

    jmp     .salir

; ------------------------------------------------------------------------
; Archivo existente — manejar acción
; ------------------------------------------------------------------------
.manejarExistente:
    cmp     byte [accion], 'l'
    je      .leerArchivoExistente
    cmp     byte [accion], 'L'
    je      .leerArchivoExistente
    cmp     byte [accion], 'e'
    je      .cerrarYEliminar
    cmp     byte [accion], 'E'
    je      .cerrarYEliminar
    cmp     byte [accion], 's'
    je      .cerrarYSobreescribir
    cmp     byte [accion], 'S'
    je      .cerrarYSobreescribir
    cmp     byte [accion], 'c'
    je      .cerrarYSoloAbrir
    cmp     byte [accion], 'C'
    je      .cerrarYSoloAbrir
    jmp     .anhiadir

.cerrarYSoloAbrir:
    push    ebx
    call    _fclose
    add     esp, 4
    push    nombreCompleto
    push    msgSiExiste
    call    _printf
    add     esp, 8
    jmp     .soloAbrir

.cerrarYSobreescribir:
    push    ebx
    call    _fclose
    add     esp, 4
    jmp     .sobreescribir

.cerrarYEliminar:
    push    ebx
    call    _fclose
    add     esp, 4
    jmp     .eliminar

.soloAbrir:
    push    nombreCompleto
    push    msgAbriendo
    call    _printf
    add     esp, 8
    push    codigoAbrir
    push    nombreCompleto
    call    _fopen
    add     esp, 8
    cmp     eax, 0
    je      .errorApertura
    mov     ebx, eax
    jmp     .leerArchivo

.sobreescribir:
    push    nombreCompleto
    push    msgSobreescribiendo
    call    _printf
    add     esp, 8
    push    codigoEscribir
    push    nombreCompleto
    call    _fopen
    add     esp, 8
    jmp     .escribir

.crear:
    push    nombreCompleto
    push    msgCreando
    call    _printf
    add     esp, 8
    push    codigoEscribir
    push    nombreCompleto
    call    _fopen
    add     esp, 8
    jmp     .escribir

.anhiadir:
    push    nombreCompleto
    push    msgAnhadiendo
    call    _printf
    add     esp, 8
    push    codigoAppend
    push    nombreCompleto
    call    _fopen
    add     esp, 8
    jmp     .escribir

.leerArchivoExistente:
    jmp     .leerArchivo

; ------------------------------------------------------------------------
; Leer archivo
; ------------------------------------------------------------------------
.leerArchivo:
    mov     dword [counter], 0
    push    nombreCompleto
    push    msgLeyendo
    call    _printf
    add     esp, 8
.bucleLeeLin:
    push    ebx
    push    longLinea
    push    auxLinea
    call    _fgets
    add     esp,12
    cmp     eax, 0
    je      .finLectura
    inc     dword [counter]
    push    auxLinea
    call    _printf
    add     esp, 4
    jmp     .bucleLeeLin
.finLectura:
    push    finArchivo
    call    _printf
    add     esp, 4
    push    dword [counter]
    push    msgCount
    call    _printf
    add     esp, 8
    push    ebx
    call    _fclose
    add     esp, 4
    jmp     .salir

; ------------------------------------------------------------------------
; Escribir (crear/añadir/sobrescribir), repite el mismo texto N veces
; ------------------------------------------------------------------------
.escribir:
    cmp     eax, 0
    je      .errorApertura
    mov     ebx, eax

    ; Pedir el texto UNA sola vez
    push    promptTexto
    call    _printf
    add     esp, 4
    push    inputBuffer
    call    _gets
    add     esp, 4

    mov     edi, [numeroLineas]
.bucleEscritura:
    cmp     dword edi, 0
    je      .cerrarArchivo
    push    inputBuffer
    push    formatoSalida
    push    ebx
    call    _fprintf
    add     esp,12
    dec     edi
    jmp     .bucleEscritura

.cerrarArchivo:
    push    ebx
    call    _fclose
    add     esp, 4
    push    nombreCompleto
    push    archivoCreado
    call    _printf
    add     esp, 8
    jmp     .salir

; ------------------------------------------------------------------------
; Error al abrir para escritura
; ------------------------------------------------------------------------
.errorApertura:
    push    Err2
    call    _printf
    add     esp, 4
    jmp     .salir

; ------------------------------------------------------------------------
; Eliminar archivo
; ------------------------------------------------------------------------
.eliminar:
    push    nombreCompleto
    push    msgEliminando
    call    _printf
    add     esp, 8
    push    nombreCompleto
    call    _remove
    add     esp, 4
    cmp     eax, 0
    jne     .errorEliminacion
    push    nombreCompleto
    push    formatDelete
    call    _printf
    add     esp, 8
    jmp     .salir

.errorEliminacion:
    push    nombreCompleto
    push    formatDeleteErr
    call    _printf
    add     esp, 8
    jmp     .salir

; ------------------------------------------------------------------------
; Salida del programa
; ------------------------------------------------------------------------
.salir:
    pop     edi
    pop     esi
    pop     ebx
    mov     esp, ebp
    pop     ebp
    ret
