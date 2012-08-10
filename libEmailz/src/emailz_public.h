//
//  emailz_public.h
//  libEmailz
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#ifndef libEmailz_emailz_public_h
#define libEmailz_emailz_public_h

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <Block.h>

struct emailz_s;
struct emailz_mail_s;
struct emailz_socket_s;
struct emailz_listener_s;

//
// emailz_socket_state_t
//
typedef enum
{
	EMAILZ_SOCKET_STATE_OPEN=1,
	EMAILZ_SOCKET_STATE_CLOSE=2
} emailz_socket_state_t;

//
// emailz_smtp_command_t
//
typedef enum
{
	EMAILZ_SMTP_COMMAND_NONE,
	EMAILZ_SMTP_COMMAND_HELO,
	EMAILZ_SMTP_COMMAND_EHLO,
	EMAILZ_SMTP_COMMAND_MAIL,
	EMAILZ_SMTP_COMMAND_RCPT,
	EMAILZ_SMTP_COMMAND_DATA,
	EMAILZ_SMTP_COMMAND_QUIT,
	EMAILZ_SMTP_COMMAND_RSET,
	EMAILZ_SMTP_COMMAND_NOOP,
	EMAILZ_SMTP_COMMAND_STARTTLS
} emailz_smtp_command_t;

//
// handlers
//
typedef void (^emailz_socket_handler_t)(struct emailz_s*, struct emailz_socket_s*, emailz_socket_state_t, void**);
typedef void (^emailz_smtp_handler_t)(struct emailz_s*, void*, emailz_smtp_command_t, unsigned char *arg);
typedef void (^emailz_header_handler_t)(struct emailz_s*, void*, unsigned char *name, unsigned char *arg);
typedef void (^emailz_data_handler_t)(struct emailz_s*, void*, size_t datalen, const void *data, bool done);
typedef void (^emailz_accept_handler_t)(struct emailz_listener_s*, int socket, struct sockaddr_in);

//
// emailz_socket_t
//
struct emailz_socket_s
{
};
typedef struct emailz_socket_s *emailz_socket_t;

//
// emailz_listener_t
//
struct emailz_listener_s
{
};
typedef struct emailz_listener_s *emailz_listener_t;

//
// emailz_t
//
struct emailz_s
{
};
typedef struct emailz_s *emailz_t;





/**
 *
 */
emailz_t emailz_create ();
void emailz_destroy (emailz_t);
bool emailz_start (emailz_t);
bool emailz_stop (emailz_t);
void emailz_set_socket_handler (emailz_t, emailz_socket_handler_t);
void emailz_record_enable (emailz_t, bool, char*);

/**
 *
 */
void emailz_socket_set_smtp_handler (emailz_socket_t, emailz_smtp_handler_t);
void emailz_socket_set_header_handler (emailz_socket_t, emailz_header_handler_t);
void emailz_socket_set_data_handler (emailz_socket_t, emailz_data_handler_t);
char* emailz_socket_get_name (emailz_socket_t);

/**
 *
 */
static char* emailz_print_number (char*, uint64_t, int);

#endif
