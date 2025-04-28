; Declaraciones externas
extern _fopen, _fclose, _fgets, _fprintf
extern _printf, _scanf, _sscanf, _remove
extern _exit, _gets, _getchar
extern _strlen, _strcpy, _strcat, _strstr

section .data
intFormat:            db "%d", 0
formatString:         db "%s", 0
charFormat:           db "%c", 0
formatoSalida:        db "%s",10,0
codigoEscribir:       db "w",0
codigoAppend:         db "a",0
codigoAbrir:          db "r",0
Err1:                 db "ERROR: el tercer argumento debe ser entero",10,0
Err2:                 db "ERROR: el archivo no puede ser abierto",10,0
Err3:                 db "ERROR: Uso correcto: programa [nombre_archivo] [accion(c=crear|a=anadir|e=eliminar|l=leer)] [lineas]",10,0
msgArgumenInvalido:   db "ERROR: Argumentos invalidos. Por favor siga el formato correcto.",10,0
msgNoExiste:          db "El archivo %s no existe.",10,0
msgPreguntaCrear:     db "¿Desea crear un nuevo archivo? (s/n): ",0
msgNombreNuevo:       db "Ingrese el nombre del nuevo archivo: ",0
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
msgLineas:            db "Se escribiran %d lineas",10,0
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
longLinea       EQU     72
auxLinea        resb    longLinea
bufferLectura   resb    1024
inputBuffer     resb    256

section .text
global _main
_main:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    ; Leer argc y argv
    mov     eax, [ebp+8]
    mov     ebx, [ebp+12]
    ; Por defecto líneas = 5
    mov     dword [numeroLineas], 5

    cmp     eax, 1
    je      .modoInteractivo
    cmp     eax, 2
    je      .soloNombre
    cmp     eax, 3
    je      .nombreYAccion
    cmp     eax, 4
    je      .todosArgumentos
    jmp     .argumentosInvalidos

.modoInteractivo:
    ; Solicitar nombre
    push    promptNombre
    call    _printf
    add     esp,4
    push    nombreArchivo
    call    _gets
    add     esp,4
    ; Solicitar acción
    push    promptAccion
    call    _printf
    add     esp,4
    call    _getchar
    mov     [accion],al
    call    _getchar
    ; Si no es leer o eliminar, pedir líneas
    cmp     byte [accion],'e'
    je      .skipLineas
    cmp     byte [accion],'E'
    je      .skipLineas
    cmp     byte [accion],'l'
    je      .skipLineas
    cmp     byte [accion],'L'
    je      .skipLineas
    push    promptLineas
    call    _printf
    add     esp,4
    push    numeroLineas
    push    intFormat
    call    _scanf
    add     esp,8
    cmp     eax,1
    jne     .setDefault5
    cmp     dword [numeroLineas],0
    jle     .setDefault5
    jmp     .afterLineas
.setDefault5:
    mov     dword [numeroLineas],5
.afterLineas:
.skipLineas:
    jmp     .procesarComando

.soloNombre:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp,8
    mov     byte [accion],'l'
    jmp     .procesarComando

.nombreYAccion:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp,8
    mov     edi,[ebx+8]
    mov     al,[edi]
    mov     [accion],al
    jmp     .procesarComando

.todosArgumentos:
    push    dword [ebx+4]
    push    nombreArchivo
    call    _strcpy
    add     esp,8
    mov     edi,[ebx+8]
    mov     al,[edi]
    mov     [accion],al
    ; Validar y sscanf líneas si aplica (omitido…) 
    jmp     .procesarComando

.argumentosInvalidos:
    push    msgArgumenInvalido
    call    _printf
    add     esp,4
    push    Err3
    call    _printf
    add     esp,4
    jmp     salir

.procesarComando:
    ; Asegurar extensión .txt
    push    nombreArchivo
    push    nombreCompleto
    call    _strcpy
    add     esp,8
    push    extensionTxt
    push    nombreCompleto
    call    _strstr
    add     esp,8
    cmp     eax,0
    jne     .openCheck
    push    extensionTxt
    push    nombreCompleto
    call    _strcat
    add     esp,8
.openCheck:
    ; Intentar abrir
    push    codigoAbrir
    push    nombreCompleto
    call    _fopen
    add     esp,8
    cmp     eax,0
    je      .archivoNoExiste
    mov     ebx,eax
    jmp     .manejarExistente

.archivoNoExiste:
    ; Notificar
    push    nombreCompleto
    push    msgNoExiste
    call    _printf
    add     esp,8
    ; Si leer, error
    cmp     byte [accion],'l'
    je      .errorApertura
    cmp     byte [accion],'L'
    je      .errorApertura
    ; Para crear/agregar/eliminar → preguntar
    cmp     byte [accion],'c'
    je      .crear
    cmp     byte [accion],'C'
    je      .crear
    jmp     .preguntarCrear

.preguntarCrear:
    push    msgPreguntaCrear
    call    _printf
    add     esp,4
    call    _getchar
    mov     [respuesta],al
    call    _getchar
    cmp     byte [respuesta],'s'
    je      .setACrear
    cmp     byte [respuesta],'S'
    je      .setACrear
    jmp     salir
.setACrear:
    mov     byte [accion],'c'
    jmp     .pedirNuevoNombre

.pedirNuevoNombre:
    push    msgNombreNuevo
    call    _printf
    add     esp,4
    push    nuevoNombre
    call    _gets
    add     esp,4
    push    nuevoNombre
    push    nuevoCompleto
    call    _strcpy
    add     esp,8
    push    extensionTxt
    push    nuevoCompleto
    call    _strstr
    add     esp,8
    cmp     eax,0
    jne     .validarNuevoNombre
    push    extensionTxt
    push    nuevoCompleto
    call    _strcat
    add     esp,8
.validarNuevoNombre:
    push    codigoAbrir
    push    nuevoCompleto
    call    _fopen
    add     esp,8
    cmp     eax,0
    je      .usarNuevoCrear
    ; Existe, cerrar y usar
    push    eax
    call    _fclose
    add     esp,4
    push    nuevoCompleto
    push    msgSiExisteSobreesc
    call    _printf
    add     esp,8
    push    nuevoCompleto
    push    nombreCompleto
    call    _strcpy
    add     esp,8
    cmp     byte [accion],'e'
    je      .eliminar
    cmp     byte [accion],'E'
    je      .eliminar
    cmp     byte [accion],'a'
    je      .anhiadir
    cmp     byte [accion],'A'
    je      .anhiadir
    jmp     .sobreescribir

.usarNuevoCrear:
    ; Nuevo no existe → crear
    push    nuevoCompleto
    push    nombreCompleto
    call    _strcpy
    add     esp,8
    jmp     .crear

.manejarExistente:
    ; Acción sobre existente
    cmp     byte [accion],'l'
    je      .leerArchivoExistente
    cmp     byte [accion],'L'
    je      .leerArchivoExistente
    cmp     byte [accion],'e'
    je      .cerrarYEliminar
    cmp     byte [accion],'E'
    je      .cerrarYEliminar
    cmp     byte [accion],'s'
    je      .cerrarYSobreescribir
    cmp     byte [accion],'S'
    je      .cerrarYSobreescribir
    cmp     byte [accion],'c'
    je      .cerrarYSoloAbrir
    cmp     byte [accion],'C'
    je      .cerrarYSoloAbrir
    jmp     .anhiadir

.cerrarYSoloAbrir:
    push    ebx
    call    _fclose
    add     esp,4
    push    nombreCompleto
    push    msgSiExiste
    call    _printf
    add     esp,8
    jmp     .soloAbrir

.cerrarYSobreescribir:
    push    ebx
    call    _fclose
    add     esp,4
    push    nombreCompleto
    push    msgSiExisteSobreesc
    call    _printf
    add     esp,8
    push    dword [numeroLineas]
    push    msgLineas
    call    _printf
    add     esp,8
    jmp     .sobreescribir

.cerrarYEliminar:
    push    ebx
    call    _fclose
    add     esp,4
    jmp     .eliminar

.soloAbrir:
    push    nombreCompleto
    push    msgAbriendo
    call    _printf
    add     esp,8
    push    codigoAbrir
    push    nombreCompleto
    call    _fopen
    add     esp,8
    cmp     eax,0
    je      .errorApertura
    mov     ebx,eax
    jmp     .leerArchivo

.sobreescribir:
    push    nombreCompleto
    push    msgSobreescribiendo
    call    _printf
    add     esp,8
    push    codigoEscribir
    push    nombreCompleto
    call    _fopen
    add     esp,8
    jmp     .escribir

.crear:
    push    nombreCompleto
    push    msgCreando
    call    _printf
    add     esp,8
    push    codigoEscribir
    push    nombreCompleto
    call    _fopen
    add     esp,8
    jmp     .escribir

.anhiadir:
    push    nombreCompleto
    push    msgAnhadiendo
    call    _printf
    add     esp,8
    push    codigoAppend
    push    nombreCompleto
    call    _fopen
    add     esp,8
    jmp     .escribir

.leerArchivoExistente:
    jmp     .leerArchivo

.leerArchivo:
    push    nombreCompleto
    push    msgLeyendo
    call    _printf
    add     esp,8
.bucleLeeLin:
    push    ebx
    push    longLinea
    push    auxLinea
    call    _fgets
    add     esp,12
    cmp     eax,0
    je      .finLectura
    push    auxLinea
    call    _printf
    add     esp,4
    jmp     .bucleLeeLin
.finLectura:
    push    finArchivo
    call    _printf
    add     esp,4
    push    ebx
    call    _fclose
    add     esp,4
    jmp     salir

.escribir:
    cmp     eax,0
    je      .errorApertura
    mov     ebx,eax
    ; Pedir texto
    push    promptTexto
    call    _printf
    add     esp,4
    push    inputBuffer
    call    _gets
    add     esp,4
    mov     edi,[numeroLineas]
.bucleEscritura:
    cmp     dword edi,0
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
    add     esp,4
    push    nombreCompleto
    push    archivoCreado
    call    _printf
    add     esp,8
    jmp     salir

.errorApertura:
    push    Err2
    call    _printf
    add     esp,4
    jmp     salir

.eliminar:
    push    nombreCompleto
    push    msgEliminando
    call    _printf
    add     esp,8
    push    nombreCompleto
    call    _remove
    add     esp,4
    cmp     eax,0
    jne     .errorEliminacion
    push    nombreCompleto
    push    formatDelete
    call    _printf
    add     esp,8
    jmp     salir

.errorEliminacion:
    push    nombreCompleto
    push    formatDeleteErr
    call    _printf
    add     esp,8
    jmp     salir

salir:
    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret
