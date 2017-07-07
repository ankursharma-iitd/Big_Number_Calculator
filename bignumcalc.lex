%{
#include "ass3.h"
#include "bignumcalc.tab.h"
#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#define YYSTYPE struct bigint
int lineNumber=0;
%}
digit [0-9]
integer {digit}+
number ("- ")?({integer}+|{integer}+"."{integer}+)
%%
{number}			{
				if(lineNumber==1)
				{
				int i=0;
				int count=0;
				if(yytext[0]=='-' && yytext[1]==' ')
				{(yylval.b).flag=-1;i+=2;
				}
				else
				(yylval.b).flag=+1;
				while(i<yyleng)
				{
				if(yytext[i]=='.') break;
				(yylval.b).x[count]=yytext[i]-'0';
				i++;
				count++;
				}
				(yylval.b).length=count;
				int j=0;
				i++;
				while(i<yyleng)
				{
				(yylval.b).frac[j]=yytext[i]-'0';
				i++;
				j++;
				}
				(yylval.b).lengthDec=j;
				return NUMBER;
				}
				else
				{
				int i=0;
				while(i<yyleng)
				{
				if(yytext[i]=='.' || yytext[i]=='-' || yytext[i]==' ')
					{printf("Invalid MAX_INT \n");
					exit(1);
					}
				i++;
				}
				
				MAX_INT=atoi(yytext);
				}

				}
"SQRT"                 {return SQT;}
"LOG "			{ return LOG_10;}
" + "		 	{return PLUS;}
" - "			{return MINUS;}
"- "			{return UMINUS;}
" * "			{return MULTIPLY;}
" / "			{return DIVIDE;}
"\n"			{lineNumber++; return END;}
"( "			{return OP;}
" )"			{return CP;}
"POW "			{ return POWER;}
%%
int yywrap(void) {
    return 1;
}
