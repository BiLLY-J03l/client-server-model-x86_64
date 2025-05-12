extern socket
extern scanf
extern printf
extern htons
extern inet_pton
extern connect
extern recv
extern close
extern atoi
extern send
extern accept
extern strlen


;https://students.mimuw.edu.pl/SO/Linux/Kod/include/linux/socket.h.html

section .data

fmt_str_1 db "[+] SOCKET CREATED -> fd : %d" , 0xa , 0x0
fmt_str_2 db "[+] SOCKET CLOSED !" , 0xa , 0x0
fmt_str_3 db "[+] PORT TO LISTEN ON -> %s", 0xa , 0x0
fmt_str_4 db "[+] BIND SUCCESS!" , 0xa , 0x0
fmt_str_5 db "[+] CLIENT: %s", 0xa , 0x0
fmt_str_6 db "[+] listening on port %d..." , 0xa , 0x0
fmt_str_7 db "[+] connection received, client fd -> %d...", 0xa ,0x0
fmt_err_str_1 db "[x] SOCKET CREATION ERR -> %d" , 0xa , 0x0
fmt_err_str_2 db "[x] SOCKET CLOSING ERR -> %d" , 0xa , 0x0
fmt_err_str_3 db "[x] SERVER ADDRESS INVALID" , 0xa , 0x0
fmt_err_str_4 db "[x] LISTENING PORT IS LESS THAN 1" , 0xa , 0x0
fmt_err_str_5 db "[x] LISTENING PORT IS MORE THAN 65535" , 0xa , 0x0
fmt_err_str_6 db "[x] LISTENING PORT IS INVALID" , 0xa , 0x0
fmt_err_str_7 db "[X] BINDING FAILED, ERR -> %d" , 0xa , 0x0
fmt_err_str_8 db "[x] CLIENT CLOSED OR CONNECTION ERR, ERR -> %d" , 0xa , 0x0
fmt_err_str_9 db "[x] LISTEN FAILED ON PORT %d, ERR -> %d" , 0xa ,0x0
fmt_err_str_10 db "[x] SENT FAILED, ERR -> %d" , 0xa , 0x0
fmt_err_str_11 db "[x] CONNECTION COULDN'T BE ACCEPTED, ERR -> %d", 0xa ,0x0
dbg_msg_1 db "[+] POPULATING sockaddr_in STRUCT" , 0xa , 0x0
dbg_msg_2 db "[+] BINDING.." , 0xa , 0x0
dbg_msg_3 db "[+] INIT LISTEN" , 0xa , 0x0
new_line db 0xa
server_addr db "0.0.0.0" , 0x0

input_msg_1 db "[+] Enter the port you want to listen on: " , 0x0
len_input_msg_1 equ $-input_msg_1


server_msg db "[+] YOU: ", 0x0
server_msg_len equ $-server_msg

motd_str db "!!!!! HAIL BILLY !!!!!"
motd_str_len equ $-motd_str

struc sockaddr_in
	.sin_family	resw 1	; 2 bytes for AF_INET
	.sin_port	resw 1	; 2 bytes
	.sin_addr	resd 1	; 4 bytes
	.sin_zero	resb 8	; 8 bytes
endstruc

sockaddr_in_struct_size equ 16

backlog_int equ 10
server_port_len equ 8
recv_msg_buf_len equ 1024
msg_to_send_len equ 100



section .bss


socket_fd resq 1	; 8 bytes for int socket = socket()
client_sock_fd resq 1
;server_addr resb 100	; 100 bytes for char server_addr[100]
server_port_str resq 1	; 8 bytes
server_port_int resq 1
server_struct resb sockaddr_in	; 16 bytes for sockaddr_in struct

recv_msg_buf resb recv_msg_buf_len + 1	; 1024 bytes

msg_to_send_str resb msg_to_send_len + 1	; 101 byttes

errno_code resq 1

section .text
global main

main:
	push rbp
	mov rbp , rsp
	
	; CREATE SOCKET
	mov rdi , 2	; AF_INET
	mov rsi , 1	; SOCK_STREAM
	mov rdx , 0
	call sock_create
	cmp rax , 0
	jl sock_create_err
	
	mov [socket_fd] , rax	;save socket_fd
	mov rdi , fmt_str_1
	mov rsi , [socket_fd]
	call printf

INPUT_HERE:
	; PRINT SERVER_ADDR INPUT PROMPT
	mov rdi , 1
	mov rsi , input_msg_1
	mov rdx , len_input_msg_1
	call prints_output
	
	
	; READ SERVER_PORT
	xor rax , rax
	mov rdi , 0
	mov rsi , server_port_str
	mov rdx , 8
	call read_input
	
	mov rbx , [server_port_str]
	
	mov [server_port_int] , rbx 
	mov rcx , rax	; e.g server_port = {'1','2','\n'}
	dec rcx		; e.g 3 bytes (ret value of read syscall)  dec by 1, so rcx -> 2 
	cmp byte [rsi + rcx] , 0x0a	; e.g server_addr[2] = = '\n'?
	mov byte [rsi + rcx] , 0x0	; replace '\n' with '\0'
	

	mov rdi , server_port_str
	call str_to_int
	mov [server_port_int] , rax
	cmp rax , 0
	jz port_str_err
	
	;cmp [server_port_int] , 1	;compare the value with 1
	cmp rax , 1
	jl port_min_err
	
	
	;cmp [server_port_int] , 65535	;compare the value with 65535
	cmp rax , 65535
	jg port_max_err

	; PRINTING SERVER ADDRESS AND PORT
	mov rdi , fmt_str_3
	mov rsi , server_port_str
	call printf ;ERROR HERE
	


	mov rdi , dbg_msg_1
	call printf	

SOCKADDR_STRUCT_POPULATE:	
	; SETUP SOCKADDR_IN STRUCT

	; sin_family 	-> AF_INET
	; sin_port	-> htons(port_no)
	; sin_addr	-> inet_pton(AF_INET,server_addr,sockaddr_struct->sin_addr)
	;struct sockaddr_in {
    		;short sin_family;      // 2 bytes
    		;unsigned short sin_port;    // 2 bytes
    		;struct in_addr sin_addr;    // 4 bytes
    		;char sin_zero[8];           // 8 bytes
	;}
	xor rdi , rdi
	mov rdi , 2	; sin_family = AF_INET
	mov word [server_struct + sockaddr_in.sin_family] , 2

	mov di , [server_port_int]
	call htons
	mov [server_struct + sockaddr_in.sin_port] , ax	; ax is the 16 bit value for rax - 2 bytes exactly
	


	mov rdi , 2	; AF_INET
	mov rsi , server_addr
	mov rdx , server_struct + sockaddr_in.sin_addr
	call inet_pton		;inet_pton(int af, const char *restrict src, void *restrict dst) ; 
	cmp rax , 0		; if the ip address is invalid
	jz server_input_err

BINDING:
	;BINDING PROCESS

	mov rdi , dbg_msg_2
	call printf	
	mov rdi , [socket_fd]
	mov rsi , server_struct
	mov rdx , sockaddr_in_struct_size	; 16 bytes -> sockaddr_in struct size
	call sock_bind
	cmp rax , 0
	jl bind_err
	mov rdi , fmt_str_4
	call printf

LISTENING:
	;START LISTEN	
	mov rdi , [socket_fd]
	mov rsi , backlog_int
	call start_listen
	cmp rax , 0
	jl listen_err
	mov rdi , fmt_str_6
	mov rsi , [server_port_int]
	call printf
	
; ERROR IN ACCEPTING CONNECTION , BAD FILE NUMBER
ACCEPT_CONN:
	;ACCEPT CONNECTIONS
	mov rdi , [socket_fd]
	mov rsi , 0
	mov rdx , 0
	call accept_conn
	cmp rax , 0
	jl accept_conn_err
	mov [client_sock_fd] , rax
	mov rdi , fmt_str_7
	mov rsi , [client_sock_fd]
	call printf


SEND_MSG:
	xor rbx , rbx	
	mov [msg_to_send_str] , rbx


	;mov rdi , new_line
	;call prints_output
;		
;	mov rdi , [client_sock_fd]
;	mov rsi , motd_str
;	mov rdx , motd_str_len
;	mov r10 , 0
;	mov r8 , server_struct
;	mov r9 , sockaddr_in_struct_size
;	call send_msg


	; PRINT -> "YOU: "
	mov rdi , 1
	mov rsi , server_msg
	mov rdx , server_msg_len
	call prints_output

	; READ INPUT TO SEND
	xor rax , rax
	mov rdi , 0
	mov rsi , msg_to_send_str
	mov rdx , msg_to_send_len
	call read_input
	
        ;mov rbx , [msg_to_send_str]
        ;mov [msg_to_send_str] , rbx 
        mov rcx , rax   ; e.g server_port = {'1','2','\n'}
        ;dec rcx         ; e.g 3 bytes (ret value of read syscall)  dec by 1, so rcx -> 2 
        ;cmp byte [rsi + rcx] , 0x0a     ; e.g server_addr[2] = = '\n'?
        mov byte [rsi + rcx] , 0x0      ; replace '\n' with '\0'
	
	mov rdi , msg_to_send_str
	call strlen
	

	
	; send(socket_fd,msg_to_send_str,sizeof(msg_to_send),0)
	;mov rdi , [client_sock_fd]
	;mov rsi , motd_str
	;mov rdx , motd_str_len	; strlen(msg_to_send) , e.g. without null-terminator	
	
	mov rdi , [client_sock_fd]
	mov rsi , msg_to_send_str
	mov rdx , rax
	call send_msg
	cmp rax , 0
	jl send_msg_err
	jmp DONE

; RECV_BUFFER HAS SOME ERRORS :<
RECV_BUFFER:
	; recvfrom(socket_fd , recv_msg_buf , sizeof(recv_msg_buf) , 0 , 0 ,0)
	mov rdi , [client_sock_fd]
	mov rsi , recv_msg_buf
	mov rdx , recv_msg_buf_len
	mov r10 , 0
	call recv_msg
	
	cmp rax , -1
	jl recv_buf_err
	;mov byte [recv_msg_buf + rax] , 0
	mov rdi , fmt_str_5
	mov rsi , recv_msg_buf
	call printf
	
	
	

DONE:
	; CLOSE SOCKET
	mov rdi , [socket_fd]
	call sock_close
	cmp rax , 0	
	mov rdi , fmt_str_2
	call printf
	jl sock_close_err
	
	leave
	ret




sock_create:
	; USE sys_socket sysacll
	push rbp
	mov rbp , rsp
	mov rax , 41
	syscall
	leave
	ret

sock_close:
	push rbp
	mov rbp , rsp
	mov rax , 3
	syscall
	leave
	ret

sock_create_err:
	neg rax
	mov [errno_code] , rax	

	mov rdi , fmt_err_str_1
	mov rsi , rax
	call printf
	
	;exit with the err code
	mov rdi , [errno_code]
	mov rax , 60
	syscall

sock_close_err:
	neg rax
	mov [errno_code] , rax

	mov rdi , fmt_err_str_2
	mov rsi , rax
	call printf
	
	;exit with the err code
	mov rdi , [errno_code]
	mov rax , 60
	syscall

accept_conn_err:
	neg rax
	mov [errno_code] , rax
	mov rdi , fmt_err_str_11
	mov rsi , rax
	call printf
	
	;exit with err code
	mov rdi , [errno_code]
	mov rax , 60
	syscall


read_input:
	push rbp
	mov rbp , rsp
	xor rax , rax
	syscall
	leave
	ret

prints_output:
	push rbp
	mov rbp , rsp
	mov rax , 1
	syscall
	leave
	ret

server_input_err:
	mov rdi , fmt_err_str_3
	call printf
	jmp INPUT_HERE

str_to_int:
	push rbp
	mov rbp , rsp
	call atoi
	leave
	ret

port_min_err:
	mov rdi , fmt_err_str_4
	call printf
	jmp INPUT_HERE

port_max_err:
	mov rdi , fmt_err_str_5
	call printf
	jmp INPUT_HERE

port_str_err:
	mov rdi , fmt_err_str_6
	call printf
	jmp INPUT_HERE

init_conn:
	push rbp
	mov rbp , rsp
	mov rax , 42
	syscall
	leave
	ret

bind_err:
	neg rax
	mov [errno_code] , rax
	mov rdi , fmt_err_str_7
	mov rsi , rax
	call printf
	
	; EXIT WIRH ERR CODE
	mov rdi , [errno_code]
	mov rax , 60
	syscall

listen_err:
	neg rax
	mov [errno_code] , rax
	mov rdi , fmt_err_str_9
	mov rsi , [server_port_int]
	mov rdx , rax
	call printf
	
	; EXIT WITH ERR CODE
	mov rdi , [errno_code]
	mov rax , 60
	syscall

recv_msg:
	push rbp
	mov rbp , rsp
	call recv
	leave
	ret

send_msg:
	push rbp
	mov rbp , rsp	
	call send
	leave
	ret

recv_buf_err:
	neg rax
	mov [errno_code] , rax
	mov rdi , fmt_err_str_8
	mov rsi , rax
	call printf
	
	; EXIT WITH ERR CODE
	mov rdi , [errno_code]
	mov rax , 60
	syscall

send_msg_err:
	neg rax
	mov [errno_code] , rax
	mov rdi , fmt_err_str_10
	mov rsi , rax
	call printf
	
	;EXIT WITH ERR CODE
	mov rdi , [errno_code]
	mov rax , 60
	syscall

sock_bind:
	push rbp
	mov rbp , rsp
	mov rax , 49
	syscall
	leave
	ret

start_listen:
	push rbp
	mov rbp , rsp
	mov rax, 50
	syscall
	leave 
	ret

accept_conn:
	push rbp
	mov rbp , rsp
	mov rax , 43
	syscall
	;call accept
	leave
	ret
