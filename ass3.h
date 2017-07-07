/*
Declarations for a calculator
*/
#include<stdbool.h>

void yyerror(char* s);

/*nodes in AST*/
int MAX_INT;

struct bigint
{
	int flag; // flag for the sign 1 for non-negative, and -1 for negative
	int x[100]; // stores the integer part
	int frac[100]; //stores the decimal part
	int length; // length of integer part
	int lengthDec; // length of fractional part
	int max_int;  //denotes the maximum length of the bigint(both integer and fractional part)
};

struct ast
{
	int nodeType;
	struct ast* l;
	struct ast* r;
};

struct numval {
	int nodeType; /* type K for constant */
	struct bigint number;
};


/* build an AST */
struct ast *newast(int nodetype, struct ast *l, struct ast *r);
struct ast *newnum(struct bigint d);

/* evaluate an AST */
struct bigint eval(struct ast *);

struct bigint getSum(struct bigint a,struct bigint b);
struct bigint getSubtraction(struct bigint c,struct bigint d);
struct bigint removeZeros(struct bigint c);
bool equal(struct bigint a, struct bigint b);
bool Greater(struct bigint a, struct bigint b);
bool isGreater(struct bigint a, struct bigint b);
struct bigint getMultiplication(struct bigint c, struct bigint d);
struct bigint getDivision(struct bigint c,struct bigint d);
struct bigint simple_remainder(struct bigint c,struct bigint d,int flag);
int simple_division(struct bigint c,struct bigint d,int flag);
struct bigint setRemainder(struct bigint temp,int factorPoint);
struct bigint getSqrt(struct bigint a);
struct bigint getLog(struct bigint a);
struct bigint get_simple_log(struct bigint x);
struct bigint adjust_with_zeros(struct bigint a);
struct bigint shift_with_zeros(struct bigint c,int number_of_zeros,int flag);
struct bigint shift_with_zeros_and_decimals(struct bigint c,int number_of_zeros,int flag);
struct bigint roundOff(struct bigint a);
struct bigint getPow(struct bigint a, struct bigint b);


/* delete and free an AST */
void treeFree(struct ast *a);

void arrayPrint(struct bigint a);
