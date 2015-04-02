
/*
 * CS354: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <signal.h>
#include "command.h"
extern char ** environ;
char * fdisp;

SimpleCommand::SimpleCommand()
{
	// Creat available space for 5 arguments
	_numberOfAvailableArguments = 5;
	_numberOfArguments = 0;
	_arguments = (char **) malloc( _numberOfAvailableArguments * sizeof( char * ) );
}

void
SimpleCommand::insertArgument( char * argument )
{
	char * rr = NULL;
	fdisp = (char*)malloc(sizeof(char)*200);
	int l = 0;
	// to deal with tilde
	if(argument[0]=='~'&&argument[1]==0){
		char * vv = NULL;
		strcat(fdisp,getenv("HOME"));
		argument++;
	} else if (argument[0]=='~'){
		strcat(fdisp,"/homes/");
		//printf("%s",fdisp);
		argument++;
		char * ll = NULL;
	}

	// to deal with '$'
	if(strchr(argument,'$')){
		int * qq = NULL;
		for(int i=0;i<strlen(argument);i++){
			if(argument[i]!='$'||argument[i+1]!='{'){
				char * mm = NULL;
				char * tmp = (char*)malloc(sizeof(char)*2);
				tmp[0] = argument[i];
				tmp[1] = '\0';
				strcat(fdisp,tmp);
				free(tmp);
				char * ii = NULL;
			} else if(argument[i]=='$'&&argument[i+1]=='{'){
				i+=2;
				char * ts = NULL;
				char * tmp1 = (char*)malloc(sizeof(char)*strlen(argument));
				l = 0;
				while(argument[i]!='}'){
					tmp1[l]=argument[i];
					l++;
					i++;
				}
				tmp1[l] = '\0';
				strcat(fdisp,getenv(tmp1));
				free(tmp1);
			}
		}
	} else {
		strcat(fdisp,argument);
	}
      //  printf("argument is %s\n",fdisp);

	if ( _numberOfAvailableArguments == _numberOfArguments  + 1 ) {
		// Double the available space
		_numberOfAvailableArguments *= 2;
		_arguments = (char **) realloc( _arguments,
				  _numberOfAvailableArguments * sizeof( char * ) );
	}

	
	_arguments[ _numberOfArguments ] = fdisp;

	// Add NULL argument at the end
	_arguments[ _numberOfArguments + 1] = NULL;
	
	_numberOfArguments++;
}

Command::Command()
{
	// Create available space for one simple command
	_numberOfAvailableSimpleCommands = 1;
	_simpleCommands = (SimpleCommand **)
		malloc( _numberOfSimpleCommands * sizeof( SimpleCommand * ) );

	_numberOfSimpleCommands = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;
	_background = 0;
	_append = 0;
}

void
Command::insertSimpleCommand( SimpleCommand * simpleCommand )
{
	if ( _numberOfAvailableSimpleCommands == _numberOfSimpleCommands ) {
		_numberOfAvailableSimpleCommands *= 2;
		_simpleCommands = (SimpleCommand **) realloc( _simpleCommands,
			 _numberOfAvailableSimpleCommands * sizeof( SimpleCommand * ) );
	}
	
	_simpleCommands[ _numberOfSimpleCommands ] = simpleCommand;
	_numberOfSimpleCommands++;
}

void
Command:: clear()
{
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		for ( int j = 0; j < _simpleCommands[ i ]->_numberOfArguments; j ++ ) {
			free ( _simpleCommands[ i ]->_arguments[ j ] );
		}
		
		free ( _simpleCommands[ i ]->_arguments );
		free ( _simpleCommands[ i ] );
	}

	if ( _outFile ) {
		free( _outFile );
	}

	if ( _inputFile ) {
		free( _inputFile );
	}

	if ( _errFile ) {
		free( _errFile );
	}

	_numberOfSimpleCommands = 0;
	_background = 0;
	_input = 0;
	_output = 0;
	_err = 0;
	_append = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;	
}

void
Command::print()
{
	printf("\n\n");
	printf("              COMMAND TABLE                \n");
	printf("\n");
	printf("  #   Simple Commands\n");
	printf("  --- ----------------------------------------------------------\n");
	
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		printf("  %-3d ", i );
		for ( int j = 0; j < _simpleCommands[i]->_numberOfArguments; j++ ) {
			printf("\"%s\" \t", _simpleCommands[i]->_arguments[ j ] );
		}
	}

	printf( "\n\n" );
	printf( "  Output       Input        Error        Background\n" );
	printf( "  ------------ ------------ ------------ ------------\n" );
	printf( "  %-12s %-12s %-12s %-12s\n", _outFile?_outFile:"default",
		_inputFile?_inputFile:"default", _errFile?_errFile:"default",
		_background?"YES":"NO");
	printf( "\n\n" );
	
}

void
Command::execute()
{
	int ret;
	int fdin, fdout, fderr;
	// Don't do anything if there are no simple commands
	if ( _numberOfSimpleCommands == 0 ) {
		prompt();
		return;
	}

	// Print contents of Command data structure
	//  print();

	// Add execution here

	int tmpin = dup(0);
	int tmpout = dup(1);
	int tmperr = dup(2);

	if(_inputFile)
	{
		fdin = open(_inputFile, O_CREAT|O_RDONLY,0666);
	}
	else
	{
		fdin = dup(tmpin);
	}
		if(_errFile && _append==0){
		fderr = open(_errFile, O_CREAT|O_WRONLY|O_TRUNC,0666);

		fdout = fderr;
	}else if(_errFile && _append==1){
		fderr = open(_errFile, O_CREAT|O_WRONLY|O_APPEND,0666);
		if( fderr < 0 )
		{
			perror("open");
			exit(0);
		}
	}else{
		fderr = dup(tmperr);
	}
	
	dup2(fderr,2);
	close(fderr);
	// For every simple command fork a new process
	for(int i = 0; i < _numberOfSimpleCommands; i++)
	{
		dup2(fdin, 0);
		close(fdin);
		// Setup i/o redirection
		if(i == _numberOfSimpleCommands - 1)
		{
			if(!_outFile)
			{
				fdout = dup(tmpout);
				
				//open(_outFile,O_CREAT|O_WRONLY|O_TRUNC,0666);
			} else if(_append) {
			    fdout = open(_outFile,O_CREAT|O_WRONLY|O_APPEND,0666);
			  _append = 0;
			} else {
			    fdout = open(_outFile,O_CREAT|O_WRONLY|O_TRUNC,0666);
			}
		}
		else
		{
			int fdpipe[2];
			pipe(fdpipe);
			fdout = fdpipe[0];
			fdin = fdpipe[1];
		}
		dup2(fdout,1);
		close(fdout);
		
		// for manipulation of "cd" *****
		if(!strcmp( _simpleCommands[i]->_arguments[0], "cd" )){
			if(_simpleCommands[i]->_arguments[1]){
			if(chdir(_simpleCommands[i]->_arguments[1])<0){
					fprintf(stderr,"cd: %s: No such file or directory\n",_simpleCommands[i]->_arguments[1] );
				}
			} else {
				chdir(getenv("HOME"));
			}
			clear();
			prompt();
return ;
		}
		
		// for setting environment variables, must be put before fork()
		if ( !strcmp( _simpleCommands[i]->_arguments[0], "setenv" ) )
		{
		      // add your code to set the environment variable
			
		      setenv(_simpleCommands[i]->_arguments[1],_simpleCommands[i]->_arguments[2],1);
			// printf("%s",_simpleCommands[i]->_arguments[1]);
			break;
		      
		} else if(!strcmp( _simpleCommands[i]->_arguments[0], "unsetenv")) {
		  
		      unsetenv(_simpleCommands[i]->_arguments[1]);
			break;
		}
		
		ret = fork();
		if(ret == 0)
		{
			if(!strcmp( _simpleCommands[i]->_arguments[0], "printenv")) {
				char **m = environ;
				while(*m){printf("%s\n",*m);
					m++;
				}
				exit(0);
			}
			execvp(_simpleCommands[i]->_arguments[0], _simpleCommands[i]->_arguments);
			perror("execvp");
			_exit(1);
		}
	}
	dup2(tmpin,0);
	dup2(tmpout,1);
	dup2(tmperr,2);
	close(tmpin);
	close(tmpout);
	close(tmperr);
	
	// and call exec
	if(!_background)
	{	
		waitpid(ret,NULL,NULL);
	}	

	// Clear to prepare for next command
	clear();
	
	// Print new prompt
	prompt();
}

// Shell implementation
extern "C" void killzombie(int l)
{
    //if(l == SIGINT) {
      printf("\n");
      Command::_currentCommand.prompt();
  //  } 
  //  else if(l == SIGCHLD){
  //    while(waitpid(-1,NULL,WNOHANG)>0);      
  //  }    
}

static void sigchldHandler(int signo){

    while(waitpid(-1,NULL,WNOHANG)>0);
}

void
Command::prompt()
{
  if(isatty(0)){
	printf("myshell>");
	fflush(stdout);
  }
}

Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;

int yyparse(void);



main()
{
	struct sigaction signalAction;

	signalAction.sa_handler = sigchldHandler;
	sigemptyset(&signalAction.sa_mask);
	signalAction.sa_flags = SA_RESTART;
	
	int error = sigaction(SIGCHLD, &signalAction, NULL );
	if ( error )
	{
	    perror( "sigaction" );
	    exit( -1 );
	}
	
	 signalAction.sa_handler = killzombie;
	 sigemptyset(&signalAction.sa_mask);
	 signalAction.sa_flags = SA_RESTART;
	 
	 error = sigaction(SIGINT, &signalAction, NULL);
         if(error)
	 {
	    perror("sigaction");
	    exit(-1);
	  }	


	
	Command::_currentCommand.prompt();
	yyparse();
}

