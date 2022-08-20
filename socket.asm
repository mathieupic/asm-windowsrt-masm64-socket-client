; =====================================================
; Socket en ASM (MASM64) / Client / WindowsRT
; Exemple d'utilisation d'une socket en Assembleur
; =====================================================

; Inclusion de MASM64 (64bits WindowsRT) 
; http://www.masm32.com/download/masm64.zip
include    \masm64\include64\masm64rt.inc

; Inclusion des fonctions système Win32 WinSock2 
; https://docs.microsoft.com/fr-fr/windows/win32/winsock/winsock-client-application
include    \masm64\include64\ws2_32.inc
includelib \masm64\lib64\ws2_32.lib

; Structure d'une adresse pour établir une connexion à un serveur 
; https://docs.microsoft.com/fr-fr/windows/win32/winsock/sockaddr-2
S_UN_B STRUCT
  s_b1 BYTE ?
  s_b2 BYTE ?
  s_b3 BYTE ?
  s_b4 BYTE ?
S_UN_B ENDS

S_UN_W STRUCT 
  s_w1 WORD ?
  s_w2 WORD ?
S_UN_W ENDS

ADDRESS_UNION UNION 
   S_un_b S_UN_B <>
   S_un_w S_UN_W <>
   S_addr DWORD  ?
ADDRESS_UNION ENDS

IN_ADDR STRUCT
  S_un ADDRESS_UNION <>
IN_ADDR ENDS

; La famille (TCP, UDP, non-définie etc.), le port, l'adresse
SOCKADDR_IN STRUCT
  sin_family    WORD    ?
  sin_port      WORD    ?
  sin_addr      IN_ADDR <>
  sin_zero      BYTE    8 dup (?)
SOCKADDR_IN ENDS

; Structure des informations en retour de l'appel à la fonction WSAStartup
; https://docs.microsoft.com/en-us/windows/win32/api/winsock/ns-winsock-wsadata
WSADATA STRUCT
  wVersion        WORD  ?
  wHighVersion    WORD  ?
  szDescription   BYTE  WSADESCRIPTION_LEN + 1 dup (?)
  szSystemStatus  BYTE  WSASYS_STATUS_LEN + 1 dup (?)
  iMaxSockets     WORD  ?
  iMaxUdpDg       WORD  ?
  lpVendorInfo    DWORD ?
WSADATA ENDS

SD_SEND equ 01h

.data

  ; Messages d'erreur
  msg_err_socket db "Erreur de creation d'une socket", 13,10,0
  msg_err_connect db "Erreur de connexion au serveur", 13,10,0
  msg_err_send db "Erreur d'envoi des donnees au serveur", 13,10,0
  msg_err_close db "Erreur de fermeture de la connexion avec le serveur", 13,10,0

  ; L'adresse IP et le port du serveur distant
  listen_ip db "142.250.179.99", 0
  listen_port dd 80

  ; Un exemple d'envoi de donnees au serveur 
  ; Une requête HTTP
  rqt_get db "GET / HTTP/1.1",13,10,
  "Host: www.google.fr",13,10,
  "User-Agent: User Agent",13,10,
  "Accept: */*",13,10,
  "Accept-Language: fr,fr-fr",13,10,
  "Accept-Encoding: identity",13,10,
  "Accept-Charset: US-ASCII",13,10,
  "Connection: close",13,10,
  "Content-Type: application/x-www-form-urlencoded",13,10,
  13,10,0

  ; Un buffer pour la réception des données
  buf db 512 dup (?)

.data?
  
  wsadata WSADATA      <>
  sock dd              ?
  sockAddr SOCKADDR_IN <>

.code

  entry_point proc
    
	; Début de l'utilisation de WinSock2
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-wsastartup
    invoke WSAStartup, 202h, ADDR wsadata
	
	; Ouverture d'une socket
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-socket
	invoke socket, AF_INET, SOCK_STREAM, IPPROTO_TCP
	; Récupération de la socket
    mov sock,eax

	; Si la socket est invalide alors affichage d'un message d'erreur et fin du programme
    cmp sock, INVALID_SOCKET
    jne connect_sock
    invoke StdOut, ADDR msg_err_socket
    jmp end_program

    connect_sock:

	; Définition de la famille
	mov [sockAddr.sin_family], AF_INET
	
	; Définition du port
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-htons
    invoke htons, listen_port
    mov [sockAddr.sin_port], ax
	
	; Définition de l'adresse
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-inet_addr
    invoke inet_addr,addr listen_ip
    mov [sockAddr.sin_addr], eax
	
	; Connexion au serveur
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-connect
	invoke connect,sock,addr sockAddr,sizeof sockAddr

	; Si la connexion  au serveur a échouée alors affichage d'un message d'erreur et fin du programme
	cmp eax, SOCKET_ERROR
    jne send_sock
    invoke StdOut, ADDR msg_err_connect
    jmp end_program

    send_sock:
	
	; Envoi des données au serveur
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-send
    invoke send, sock, addr rqt_get, sizeof rqt_get, 0
    
	; Si l'envoi des données au serveur a échoué alors affichage d'un message d'erreur et fin du programme
	cmp eax, SOCKET_ERROR
    jne close_sock
    invoke StdOut, ADDR msg_err_send
    jmp end_program

    close_sock:

	; Fermeture de la connexion avec le serveur
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-shutdown
    invoke shutdown, sock, SD_SEND
    
	; Si la fermeture de la connexion avec le serveur a échouée alors affichage d'un message d'erreur et fin du programme
	cmp eax, SOCKET_ERROR
    jne recv_sock
    invoke StdOut, ADDR msg_err_close

    recv_sock:

	; Récupération de la réponse du serveur dans le buffer
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-recv
    invoke recv, sock, addr buf, sizeof buf, 0
    
	; S'il n'y a plus de données alors fin du programme
	cmp eax, 0
    je end_program
	
	; Affichage de la réponse dans la console
    invoke StdOut, ADDR buf
    jmp recv_sock

    end_program:
	
	; Fin de l'utilisation de WinSock2
	; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-wsacleanup
    invoke WSACleanup
    invoke ExitProcess,0
    ret
	
  entry_point endp

end

	