%name-prefix="gdbmi_"
%defines

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "gdbmi_il.h"

extern char *gdbmi_text;
extern int gdbmi_lex ( void );
void gdbmi_error (const char *s);
output_ptr syntax_tree;
%}

%token OPEN_BRACE 		/* { */
%token CLOSED_BRACE 	/* } */
%token ADD_OP 			/* + */
%token MULT_OP 			/* * */
%token EQUAL_SIGN 		/* = */
%token TILDA 			/* ~ */
%token AT_SYMBOL 		/* @ */
%token AMPERSAND 		/* & */
%token OPEN_BRACKET 	/* [ */
%token CLOSED_BRACKET 	/* ] */
%token NEWLINE 			/* \n \r\n \r */
%token INTEGER_LITERAL 	/* A number 1234 */
%token STRING_LITERAL 	/* A string literal */
%token CSTRING 			/* "a string like \" this " */
%token COMMA 			/* , */
%token CARROT 			/* ^ */
%token STOPPED 			/* stopped */
%token DONE 			/* done */
%token RUNNING 			/* running */
%token CONNECTED 		/* connected */
%token ERROR 			/* error */
%token EXIT 			/* exit */
%token GDB 				/* (gdb) */

%union {
	struct output *u_output;
	struct oob_record *u_oob_record;
	struct result_record *u_result_record;
	int u_result_class;
	int u_async_record_kind;
	struct result *u_result;
	long u_token;
	struct async_record *u_async_record;
	struct stream_record *u_stream_record;
	int u_async_class;
	char *u_variable;
	struct value *u_value;
	struct tuple *u_tuple;
	struct list *u_list;
	int u_stream_record_kind;
}

%type <u_output> opt_output_list
%type <u_output> output_list
%type <u_output> output
%type <u_oob_record> oob_record
%type <u_oob_record> opt_oob_record_list
%type <u_result_record> opt_result_record
%type <u_result_record> result_record
%type <u_result_class> result_class
%type <u_async_record_kind> async_record_class
%type <u_result> result_list
%type <u_result> result
%type <u_token> opt_token
%type <u_token> token
%type <u_async_record> async_record
%type <u_stream_record> stream_record
%type <u_async_class> async_class
%type <u_variable> variable
%type <u_value> value
%type <u_value> value_list
%type <u_tuple> tuple
%type <u_list> list
%type <u_stream_record_kind> stream_record_class


%start opt_output_list

%%


opt_output_list: {
};

opt_output_list: output_list {
	$$ = $1;	
	printf ( "Parser passed\n" );
};

output_list: output {
	$$ = $1;
};

output_list: output_list output {
	$$ = append_to_list ( $1, $2 );
};

output: opt_oob_record_list opt_result_record GDB NEWLINE { 
	syntax_tree = malloc ( sizeof ( struct output ) );
	syntax_tree->oob_record = $1;
	syntax_tree->result_record = $2;
	printf ("VALID\n" ); 
} ;

opt_oob_record_list: {
	$$ = NULL;
};

opt_oob_record_list: opt_oob_record_list oob_record NEWLINE {
	$$ = append_to_list ( $1, $2 );
};

opt_result_record: {
	$$ = NULL;
};

opt_result_record: result_record NEWLINE {
	$$ = $1;
};

result_record: opt_token CARROT result_class {
	$$ = malloc ( sizeof ( struct result_record ) );
	$$->token = $1;
	$$->result_class = $3;
	$$->result = NULL;
};

result_record: opt_token CARROT result_class COMMA result_list {
	$$ = malloc ( sizeof ( struct result_record ) );
	$$->token = $1;
	$$->result_class = $3;
	$$->result = $5;
};

oob_record: async_record {
	$$ = malloc ( sizeof ( struct oob_record ) );
	$$->record = GDBMI_ASYNC;
	$$->variant.async_record = $1;
};

oob_record: stream_record {
	$$ = malloc ( sizeof ( struct oob_record ) );
	$$->record = GDBMI_STREAM;
	$$->variant.stream_record = $1;
};

async_record: opt_token async_record_class async_class {
	$$ = malloc ( sizeof ( struct async_record ) );
	$$->token = $1;
	$$->async_record = $2;
	$$->async_class = $3;
};

async_record: opt_token async_record_class async_class COMMA result_list {
	$$ = malloc ( sizeof ( struct async_record ) );
	$$->token = $1;
	$$->async_record = $2;
	$$->async_class = $3;
	$$->result_ptr = $5;
};

async_record_class: MULT_OP {
	$$ = GDBMI_EXEC;
};

async_record_class: ADD_OP {
	$$ = GDBMI_STATUS;
};

async_record_class: EQUAL_SIGN {
	$$ = GDBMI_NOTIFY;	
};

result_class: DONE {
	$$ = GDBMI_DONE;
};

result_class: RUNNING {;
	$$ = GDBMI_RUNNING;
};

result_class: CONNECTED {
	$$ = GDBMI_CONNECTED;
};

result_class: ERROR {
	$$ = GDBMI_ERROR;
};

result_class: EXIT {
	$$ = GDBMI_EXIT;
};

async_class: STOPPED {
	$$ = GDBMI_STOPPED;
};

result_list: result {
	$$ = append_to_list ( NULL, $1 );	
};

result_list: result_list COMMA result {
	$$ = append_to_list ( $1, $3 );
};

result: variable EQUAL_SIGN value {
	$$ = malloc ( sizeof ( struct result ) );	
	$$->variable = $1;
	$$->value = $3;
};

variable: STRING_LITERAL {
	$$ = strdup ( gdbmi_text );
};

value_list: value {
	$$ = append_to_list ( NULL, $1 );	
};

value_list: value_list COMMA value {
	$$ = append_to_list ( $1, $3 ); 
};

value: CSTRING {
	$$ = malloc ( sizeof ( struct value ) );
	$$->value_kind = GDBMI_CSTRING;
	$$->variant.cstring = strdup ( gdbmi_text ); 
};

value: tuple {
	$$ = malloc ( sizeof ( struct value ) );
	$$->value_kind = GDBMI_TUPLE;
	$$->variant.tuple = $1;
};

value: list {
	$$ = malloc ( sizeof ( struct value ) );
	$$->value_kind = GDBMI_LIST;
	$$->variant.list = $1;
};

tuple: OPEN_BRACE CLOSED_BRACE {
	$$ = NULL;
};

tuple: OPEN_BRACE result_list CLOSED_BRACE {
	$$ = malloc ( sizeof ( struct tuple ) );
	$$->result = $2;
};

list: OPEN_BRACKET CLOSED_BRACKET {
	$$ = NULL;
};

list: OPEN_BRACKET value_list CLOSED_BRACKET {
	$$ = malloc ( sizeof ( struct list ) );
	$$->list = GDBMI_VALUE;
	$$->variant.value = $2;
};

list: OPEN_BRACKET result_list CLOSED_BRACKET {
	$$ = malloc ( sizeof ( struct list ) );
	$$->list = GDBMI_RESULT;
	$$->variant.result = $2;
};

stream_record: stream_record_class CSTRING {
	$$ = malloc ( sizeof ( struct stream_record ) );
	$$->stream_record = $1;
	$$->cstring = strdup ( gdbmi_text );
};

stream_record_class: TILDA {
	$$ = GDBMI_CONSOLE;
};

stream_record_class: AT_SYMBOL {
	$$ = GDBMI_TARGET;
};

stream_record_class: AMPERSAND {
	$$ = GDBMI_LOG;
};

opt_token: {
	$$ = -1;	
};

opt_token: token {
	$$ = $1;
};

token: INTEGER_LITERAL {
	$$ = atol ( gdbmi_text );	
};