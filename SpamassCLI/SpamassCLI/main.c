//
//  main.c
//  SpamassCLI
//
//  Created by Curtis Jones on 2012.08.04.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <emailz.h>

int
main (int argc, const char *argv[])
{
	emailz_t emailz = emailz_create();
	
	/*
	emailz_set_socket_handler(emailz, ^ (emailz_t emailz, emailz_socket_t socket, emailz_socket_state_t state, void **context) {
		printf("%s.. socket! [%d]\n", state);
		
		emailz_socket_set_smtp_handler(socket, ^ (emailz_t emailz, void *_context, emailz_smtp_command_t command, unsigned char *arg) {
			printf("%s.. command=%d, arg=%s\n", command, arg);
		});
		
		emailz_socket_set_data_handler(socket, ^ (emailz_t emailz, void *context, size_t datalen, const void *data, bool done) {
			printf("%s.. datalen=%lu, data=%s\n", datalen, (char *)data);
		});
	});
	*/
	
	emailz_start(emailz);
	
	dispatch_main();
	
	return EXIT_SUCCESS;
}
