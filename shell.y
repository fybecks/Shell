
/*
 * CS-413 Spring 98
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%token	<string_val> WORD

%token 	NOTOKEN, GREAT, NEWLINE, GREATGREAT, LESS, GREATAMPERSAND, GREATGREATAMPERSAND, AMPERSAND, PIPE, 

%union	{
  char   *string_val;
	}

%{
extern "C" int yylex();
#define yylex yylex

#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<string.h>
#include<regexp.h>
#include <dirent.h>
#include <assert.h>
#include"command.h"





#define MAXFILENAME 1024
 char ** dir_arr;
 int maxEntries = 10;
 int nEntries = 0;
 int iFlag=0;

 





%}

%%

goal:	
        commands
	;


commands: simple_command
        | commands simple_command
	;

simple_command:	
	pipe_list io_modifier_list back_ground  NEWLINE {
	  //		printf("   Yacc: Execute command\n");
	        
		Command::_currentCommand.execute();
	}
	| NEWLINE 
	| error NEWLINE { yyerrok; }
        
	;

io_modifier_list:
        io_modifier_list io_modifier 
        |
        ;

command_and_args:
	command_word arg_list {
		Command::_currentCommand.
			insertSimpleCommand( Command::_currentSimpleCommand );
	}	
        ;

pipe_list: 
        pipe_list PIPE command_and_args
        |command_and_args
        ;


arg_list:
	arg_list argument
	| /* can be empty */
	;

argument:
	WORD {
	  //	  printf("   Yacc: insert argument \"%s\"\n", $1);
	//Command::_currentSimpleCommand->insertArgument( $1 );
	  char * argument = $1;
	  expandWildcardsIfNecessary($1);
	  
	}
	;

command_word:
	WORD {
	  //printf("   Yacc: insert command \"%s\"\n", $1);
	       Command::_currentSimpleCommand = new SimpleCommand();
	       Command::_currentSimpleCommand->insertArgument( $1 );
		// Command::_currentCommand._append =0;
	}
	;

io_modifier:
	GREAT WORD {
	  //printf("   Yacc: insert output \"%s\"\n", $2);
	  if(Command::_currentCommand._output==0){
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._output=1;
		// Command::_currentCommand._errFile = $2;
		// Command::_currentCommand._append =0;
	  }else{
	    printf("Ambiguous output redirect.\n");
	  }
	  
	  
	}
	|
        GREATGREAT WORD {
	  if(Command::_currentCommand._output==0){
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._output=1;
		Command::_currentCommand._append=1;
		// Command::_currentCommand._errFile = $2;
		// Command::_currentCommand._append =0;
	  }else{
	    printf("Ambiguous output redirect.\n");
	  }
		// printf("   Yacc: append output \"%s\"\n", $2);
		//if(Command::_currentCommand._outFile==0){
	
		//Command::_currentCommand._errFile = $2;
	
	//  } else {
	//	  printf("Ambiguous output redirect\n");
	//     }

	}
	|
        
        GREATAMPERSAND WORD {
	  //printf("   Yacc: insert both output and erroutput \"%s\"\n", $2);
	        Command::_currentCommand._outFile = $2;
		Command::_currentCommand._errFile = $2;
		Command::_currentCommand._output=1;
		Command::_currentCommand._err=1;
		//Command::_currentCommand._append =1;
	
        }
        |
        GREATGREATAMPERSAND WORD {
	  //printf("   Yacc: insert output and erroutput appends to \"%s\"\n", $2);
	        Command::_currentCommand._outFile = $2;
		Command::_currentCommand._errFile = $2;
		Command::_currentCommand._output=1;		
		Command::_currentCommand._append=1;
		Command::_currentCommand._err=1;
	       
	}
        |
        LESS WORD {
	  //printf("   Yacc: insert input \"%s\"\n", $2);
		Command::_currentCommand._inputFile = $2;
		Command::_currentCommand._input=1;
		// Command::_currentCommand._errFile = $2;
		// Command::_currentCommand._append =0;
	
	}
         ;
back_ground: 
        AMPERSAND {
	  //printf("   Yacc: running in the background \n" );
		Command::_currentCommand._background=1;

	}
        |
         ;



%%

void insertionSort(char **a, int size){
	int j = 0;
	char * key = NULL;
 for (int i=1; i < size; ++i) // use pre-increment to avoid unneccessary temorary object
        {
                key= a[i];
                j = i-1;
                while((j >= 0) && (strcmp(a[j], key)>0))
                {
                        a[j+1] = a[j];
                        j -= 1;
                }
                a[j+1]=key;
        }
}

/*void quickSort(char **a, int lo, int hi){

	int i = lo, j = hi;
	char * h = NULL;
	char * x = a[(lo+hi)/2];

	//partition
	do
	{
		while(strcmp(a[i],x)<0) i++;
		while(strcmp(a[j],x)>0) j--;
		if(i <= j){
			strcpy(h,a[i]);
			strcpy(a[i],a[j]);
			strcpy(a[j],h);
			i++; j--;
		}
	}while(i<=j);

	//recursion
	if(lo<j) quickSort(a,lo,j);
	if(i<hi) quickSort(a,i,hi);
}
*/
   void expandWildcard (char* prefix, char* suffix){
     
     char* unfold_dir;
	char prefix1[MAXFILENAME];
           
      if(suffix[0] == 0){
	if(nEntries == maxEntries){
	  maxEntries *= 2;
	  dir_arr = (char**)realloc(dir_arr, maxEntries*sizeof(char*));
	  assert(dir_arr!=NULL);
        }
        dir_arr[nEntries++] = strdup(prefix);
	iFlag++;
	return;
      }
         

      char* s = strchr(suffix, '/');
      char component[MAXFILENAME];
      if(s != NULL){
	char * t = NULL;
	if(s-suffix != 0){
	  strncpy(component, suffix, s-suffix);
	  component[strlen(suffix)-strlen(s)] = 0;
	}else{
	  component[0] = '\0';
	}
	suffix = s + 1;
      } else{
	strcpy(component, suffix);
	suffix = suffix + strlen(suffix);
      }
   
      
    if(strchr(component, '*') == NULL && strchr(component, '?') == NULL){
      if( component[0] != '\0'&&prefix == NULL){
	long int* s = NULL;
	sprintf(prefix1, "%s", component);
      }else if(component[0] != '\0'){
	sprintf(prefix1,"%s/%s", prefix, component);
      }

      if(component[0] != '\0'){
	expandWildcard(prefix1, suffix);
      }else{
      	expandWildcard("", suffix);
      }
      return;
    }

	//deal with '.' and '?'
    char * reg = (char*)malloc(2*strlen(component)+10);
    char * a = component;
    char * r = reg;
    char * tt = NULL;
    *r = '^'; r++; // match beginning of line    
     while (*a) {
      if (*a == '*') { *r='.'; r++; *r='*'; r++;}
      else if (*a == '?') { *r='.'; r++;}
      else if (*a == '.') { *r='\\'; r++; *r='.'; r++;}
      else { *r=*a; r++;}
      a++;
    }
    *r='$'; r++; *r=0;// match end of line and add null char
    
    char* expbuf = compile(reg,0,0);
    
    if(expbuf == NULL){
      perror("compile");
      return;
    }

    
    if(prefix == NULL){
	char * yy = NULL;
	unfold_dir = ".";
      }else if(!strcmp("", prefix)){
	unfold_dir = strdup("/");
      } else{
	char * ym = NULL;
	unfold_dir = prefix;
      }
      


    DIR *dir = opendir(unfold_dir);

    if(dir == NULL){
      return;
    }

    struct dirent64 *ent;

    while ((ent = readdir64(dir))!= NULL) {
      //printf("in the while loop\n");
      // Check if name matches
      if (advance(ent->d_name, expbuf)) {

	// recursion
	if(ent->d_name[0] != '.'){
	  if(prefix != NULL){
	    sprintf(prefix1,"%s/%s", prefix, ent->d_name);
	  }else{
	    sprintf(prefix1,"%s",ent->d_name);
	  }
	  expandWildcard(prefix1,suffix);
	}
	if(ent->d_name[0] == '.'){
	  if(component[0] == '.'){
	    if(prefix != NULL){
	      sprintf(prefix1,"%s/%s", prefix, ent->d_name);
	    }else{
	      sprintf(prefix1,"%s",ent->d_name);
	    }
	    expandWildcard(prefix1,suffix);
	  }
	}

      }
    }
    closedir(dir);
    return;
   }

void expandWildcardsIfNecessary(char * argument){
 	char * args = NULL;

	//printf("%s",arg);

  
 int count=0;
  if(strchr(argument, '\\') != NULL){
    args = (char*)malloc(strlen(argument));
    int *pp = NULL;
    for(int p=0;p<strlen(argument);p++){
      if(argument[p] != '\\'){
	char * oo = NULL;
	args[count++]=argument[p];
      }else if(argument[p] == '\\' && argument[p+1] == '\\' ){
	char *z = NULL;
	args[count++]='\\';
	
      }
    }
  }else{
    args = strdup(argument);  
  }
  //printf("%s",arg);


  //no wildcard situation.
if(args != NULL){
  if((!strchr(args,'*')&&!strchr(args,'?'))){
    int * xx = NULL;
    Command::_currentSimpleCommand->insertArgument(args);
    return;
//printf("%s",arg);
  }
  
  if(dir_arr == NULL){
    char *jj = NULL;
    dir_arr = (char**) malloc(maxEntries*sizeof(char*));
  }

  iFlag=0;
  expandWildcard(NULL,args);
  //printf("%s",arg);

  if(iFlag==0){
    char * ww = NULL;
    dir_arr[0] = strdup(args);
    nEntries++;
  //printf("%s",arg);
  }
}
	char *u = NULL;
	insertionSort(dir_arr,nEntries);
  
    for(int i=0;i<nEntries;i++){
       Command::_currentSimpleCommand->insertArgument(strdup(dir_arr[i]));
    }
	nEntries=0;
    char * entr = NULL;
    maxEntries=20;
    iFlag=0;
    int * bb = NULL;
    dir_arr=NULL;
    free(dir_arr);
    
}


void
yyerror(const char * s)
{
	fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif







