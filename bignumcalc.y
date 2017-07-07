%{
#include <stdio.h>
#include <stdlib.h> 
#include <stdarg.h> 
#include <stdbool.h>
#include "ass3.h"
%}

%union{
	struct ast *a;
	struct bigint b;
};

%token <b>NUMBER
%token END
%token OP CP
%token SQT LOG_10
%left PLUS MINUS
%left MULTIPLY DIVIDE
%left POWER
%nonassoc UMINUS

%type <a>Expr Line Term
%start Input

%%
Input:
	|Input Line  ; 

Line:END
     | Expr END	        {
			arrayPrint(roundOff(removeZeros(eval($1))));
			treeFree($1);
			exit(1);
			}
      ;

Expr: Term			 
     | Expr PLUS Expr            { $$ = newast(PLUS,$1,$3);  } 
     | Expr MINUS Expr           { $$ = newast(MINUS,$1,$3); }
     | Expr MULTIPLY Expr	 { $$ = newast(MULTIPLY,$1,$3); }
     | Expr DIVIDE Expr	         { $$ = newast(DIVIDE,$1,$3); }
     ;


Term: NUMBER                    {$$=newnum($1);}
     | OP Expr CP               {$$=$2;}
     | UMINUS Term              { 
				$$=newast(UMINUS,$2,NULL);
				}
     | SQT Term			{
				$$=newast(SQT,$2,NULL);
				}
     | LOG_10 Term		{
				$$=newast(LOG_10,$2,NULL);
				}
     | Term POWER Term		{
     				$$=newast(POWER,$1,$3);
     				}
     ;
%%

struct ast* newast(int nodeType,struct ast *l,struct ast *r)
{
	struct ast* a=calloc(100,sizeof(struct ast));

	if(!a)
	{
	yyerror("out of space");
	}

	a->nodeType=nodeType;
	a->l=l;
	a->r=r;

	return a;
}


struct ast* newnum(struct bigint d)
{
struct numval *a = calloc(100,sizeof(struct numval));
if(!a) {
yyerror("out of space");
exit(0);
}
a->nodeType = 'K';
a->number = d;
return (struct ast *)a;
}

struct bigint eval(struct ast *a)
{
struct bigint v; 
switch(a->nodeType) {
case 'K': v = (((struct numval *)a)->number); break;
case PLUS:  {v =(struct bigint)getSum(eval(a->l),eval(a->r));  break;}
case MINUS: {v=(struct bigint)getSubtraction(eval(a->l),eval(a->r));  break;}
case MULTIPLY: {v=(struct bigint)getMultiplication(eval(a->l),eval(a->r)); break;}
case UMINUS:   {v=(struct bigint)eval(a->l); 
		 if(v.flag==1)
			v.flag=-1;
		 else
			v.flag=1;
		break;}
case SQT:    {v=(struct bigint)getSqrt(eval(a->l)); break;}
case LOG_10: {v=(struct bigint)getLog(eval(a->l)); break;}
case DIVIDE:   {v=(struct bigint)getDivision(eval(a->l),eval(a->r));  break;}
case POWER:    {v=(struct bigint)getPow(eval(a->l),eval(a->r)); break;}
default: printf("internal error: bad node %c\n", a->nodeType);
}
return v;
}

struct bigint getPow(struct bigint a, struct bigint b)
{
	int i;
	struct bigint temp;
	struct bigint result=a;
	for(i=0;i<100;i++)
	{
		temp.x[i]=0;
		temp.frac[i]=0;
	}
	temp.x[0]=1;
	temp.length=1;
	temp.lengthDec=0;
	temp.flag=1;
	b=getSubtraction(b,temp);
	while(b.x[0]>0)
	{
		result=getMultiplication(result,a);
		b=getSubtraction(b,temp);	
	}
	return result;
}


struct bigint roundOff(struct bigint a)
{

	struct bigint result;
	struct bigint temp;
	int saveFlag=a.flag;
	int i;
	int currlen=a.length+a.lengthDec;
	if(currlen<=MAX_INT)
	return a;
	else if(a.length>MAX_INT)
	{
		printf("LowPrec\n");
		exit(1);
	}
	else
	{
		a.flag=1;
		temp.length=a.length;
		temp.flag=1;
		temp.lengthDec=MAX_INT-a.length+1;
		for(i=0;i<100;i++)
		{
		temp.x[i]=0;
		result.x[i]=0;
		}
		for(i=0;i<100;i++)
		{
		temp.frac[i]=0;
		result.frac[i]=0;
		}
		if(a.frac[MAX_INT-a.length]>=5)
		{
		temp.frac[MAX_INT-a.length-1]=1;
		result=getSum(a,temp);
		}
		else 
		{
		temp.frac[MAX_INT-a.length]=a.frac[MAX_INT-a.length];
		result=getSubtraction(a,temp);
		}
		result.length=a.length;
		result.lengthDec=MAX_INT-a.length;
		//printf("temp\n");
		//arrayPrint(temp);
		result.flag=saveFlag;
		return result;
	}
	
}




struct bigint getLog(struct bigint a)
{
//takes logarithm of this number assuming base 10

a=removeZeros(a);
if(a.flag==-1)
	{
	printf("Logerr\n");
	exit(1);
	}

if(a.flag==1)
	{
	if(a.length==1 && a.lengthDec==1 && a.x[0]==0 && a.frac[0]==0)
		{
		printf("Logerr\n");
		exit(1);
		}
	else
		{
		struct bigint nine,one,ten,zero,mid,ans;

		nine.length=1;
		nine.x[0]=9;
		nine.lengthDec=1;
		nine.frac[0]=0;
		nine.flag=1;
		nine=removeZeros(nine);

		ten.length=2;
		ten.x[0]=1;
		ten.x[1]=0;
		ten.lengthDec=1;
		ten.frac[0]=0;
		ten.flag=1;
		ten=removeZeros(ten);


		one.length=1;
		one.x[0]=1;
		one.lengthDec=1;
		one.frac[0]=0;
		one.flag=1;
		one=removeZeros(one);

		zero.length=1;
		zero.x[0]=0;
		zero.frac[0]=0;
		zero.lengthDec=1;
		zero.flag=1;
		zero=removeZeros(zero);
		
		if(Greater(a,nine))
		{
		mid=(getSum(one,getLog(getDivision(a,ten))));
		return mid;
		}
		else
		{
		return zero;
		}

		}	
	}
}

struct bigint adjust_with_zeros(struct bigint a)
{
	a=removeZeros(a);
	//printf("whatt\n");
	//arrayPrint(a);

	if(a.lengthDec==1 && a.frac[0]==0)
		return a;

	if(a.lengthDec%2==0)
		return a;
	else
		{
		a.frac[a.lengthDec]=0;
		a.lengthDec=a.lengthDec+1;
		return a;
		}
}

struct bigint shift_with_zeros_and_decimals(struct bigint c,int number_of_zeros,int flag)
{

	int len=c.length;
	int dec=c.lengthDec;

	int* p;
	int i;
	p=(int*)calloc(1000,sizeof(int));

	for(i=0;i<number_of_zeros;i++)
	{
	p[i]=0;
	}

	for(i=0;i<dec;i++)
	{
	p[i]=c.frac[i];
	}
	
	// flag 0 for left shift

	if(flag==0) {// left shift by that many zeros
		c.length=len+number_of_zeros;
		c.lengthDec=1;
		c.frac[0]=0;
		for(i=0;i<number_of_zeros;i++)
			{	
			c.x[i+len]=0;
			}
		
		for(i=0;i<number_of_zeros;i++)
			{
			c.x[i+len]=p[i];
			}
		}
	return c;

}

struct bigint getSqrt(struct bigint a)
{
	a=adjust_with_zeros(a);
	int num_shift=20;
	a=shift_with_zeros_and_decimals(a,num_shift,0); //left shift by some zeros
	
	a=removeZeros(a);
	if(a.flag==1)
	{
		//Base Case
		if(a.length==1 && (a.x[0]==0 || a.x[0]==1))
			return a;
		
		//Binary Search for getSqrt(a)
		struct bigint start,end=a,ans,mid,two,one;
		start.length=1;
		start.x[0]=1;
		start.lengthDec=1;
		start.frac[0]=0;
		start.flag=1;
		start=removeZeros(start);

		//defining two
		two.length=1;
		two.x[0]=2;
		two.lengthDec=1;
		two.frac[0]=0;
		two.flag=1;
		two=removeZeros(two);

		//defining one
		one.length=1;
		one.x[0]=0;
		one.lengthDec=1;
		one.frac[0]=0;
		one.flag=1;
		one=removeZeros(one);

		while(isGreater(end,start))
		{
		
		mid=getSum(start,end);
		mid=getDivision(mid,two);

		//If a is a perfect square
		if(equal(getMultiplication(mid,mid),a)){
			mid=shift_with_zeros(mid,num_shift/2,1);
			return mid;}
		
		if(Greater(a,(getMultiplication(mid,mid))))
		{
			start=getSum(mid,one);
			ans=mid;
		}
		else
			end=getSubtraction(mid,one);
		}
		ans=shift_with_zeros(ans,num_shift/2,1);
		return ans;	
	}
	else
	{
	printf("SqrtErr\n");
	exit(1);
	}

}

bool equal(struct bigint a,struct bigint b)
{
//doesnt use flags; only compares the magnitudes
    a=removeZeros(a);
    b=removeZeros(b);
    int i;
    if(a.length!=b.length) {return false;}
    else if(a.lengthDec!=b.lengthDec) {return false;}
    else                  //both fractional and int parts have equal length
    {
        for(i=0;i<a.length;i++)
        {
            if(a.x[i]!=b.x[i]) return false;
        }
        for(i=0;i<a.lengthDec;i++)
        {
            if(a.frac[i]!=b.frac[i]) return false;
        }
    }
    return true;
}

bool Greater(struct bigint a, struct bigint b)
{
    a=removeZeros(a);
    b=removeZeros(b);
    int i;
    if(a.length>b.length) return true;
    else if(a.length<b.length) return false;
    else  //both have same length of integer part
    {        
        for(i=0;i<a.length;i++) 
        {
            if(a.x[i]>b.x[i]) return true; //integer part of a>b
            else if(b.x[i]>a.x[i]) return false; //integer b>int a
	    else continue;
        }
        
        //both integer parts are equal
        //compare fractional parts
        if(a.lengthDec>b.lengthDec) return true;
        else if(a.lengthDec<b.lengthDec) return false;
        //fractional length is same
        for(i=0;i<a.lengthDec;i++) 
        {
            if(a.frac[i]>b.frac[i]) return true; //fractional part of a>b
            else if(b.frac[i]>a.frac[i]) return false; //fractional b>fractional a
        }
        
    }  
    return false;
}

bool isGreater(struct bigint a, struct bigint b)
{
    a=removeZeros(a);
    b=removeZeros(b);
    if(Greater(a,b) || equal(a,b)) return true;
    else return false; 
}

struct bigint removeZeros(struct bigint c)   //both leading and trailing zeros
{
	int l1=c.length;
	int i=0,markInt=-1;
	for(i=0;i<l1;i++)
	{
		if(c.x[i]!=0)
		{
		markInt=i;
		break;}
	}
	if(markInt==-1)
	{
	c.length=1;
	c.x[0]=0;
	}
	else
	{
	int* A;
	A=(int*)calloc(1000,sizeof(int));

	for(i=0;i<(l1-markInt);i++)
	{
	A[i]=c.x[i+markInt];
	}

	for(i=0;i<(l1-markInt);i++)
	{
	c.x[i]=A[i];   //ReAssigning the values
	}
	c.length=l1-markInt;
	}

	int l2=c.lengthDec;
	int markDec=-1;
	for(i=l2-1;i>=0;i--)
	{
		if(c.frac[i]!=0)
		{
		markDec=i;
		break;
		}
	}

	if(markDec==-1)
	{
	c.lengthDec=1;
	c.frac[0]=0;
	}
	else
	c.lengthDec=markDec+1;

	return c;
}

struct bigint getSubtraction(struct bigint c,struct bigint d)
{
// input is such that c is large in magnitude than d
	struct bigint r;

	c=removeZeros(c);
	d=removeZeros(d);
	if(c.flag==1 && d.flag==1)
	{
	if(isGreater(c,d))
	{
	
	int max,i,borrow=0,len1,len2;
	int *p=(int*) calloc(1000,sizeof(int));
	int *q=(int*) calloc(1000,sizeof(int));
	int *s=(int*) calloc(1000,sizeof(int));
	int *t=(int*) calloc(1000,sizeof(int));
	int *u=(int*) calloc(1000,sizeof(int));
	int *v=(int*) calloc(1000,sizeof(int));
	len1=c.lengthDec;
	len2=d.lengthDec;
	
	for(i=0;i<len1;i++)
	{
		s[i]=c.frac[i];
	}
	
	for(i=0;i<len2;i++)
	{
		t[i]=d.frac[i];
	}
	
	
	if(len1>=len2)
	{
	max=len1;
		for(i=len2;i<len1;i++)
		{
		t[i]=0;
		}
	}
	else
	{
	max=len2;
		for(i=len1;i<len2;i++)
		{
		s[i]=0;
		}
	}
	
	for(i=0;i<max;i++)
	{
		u[i]=s[max-i-1];
	}
	
	for(i=0;i<max;i++)
	{
		v[i]=t[max-i-1];
	}
	
	int res[max];
	
	for(i=0;i<max;i++)
	{
		if(borrow==1)
			u[i]=u[i]-1;
		if(u[i]<v[i])
		{
			u[i]=u[i]+10;
			borrow=1;
		}
		else borrow=0;
		res[i]=u[i]-v[i];	
	}
	for(i=0;i<max;i++)
	{
		r.frac[i]=res[max-i-1];
	}
	r.lengthDec=max;
	
	//reverse
	len1=c.length;
	len2=d.length;
	for(i=0;i<len1;i++)
	{
		p[i]=c.x[len1-i-1];
	}
	
	for(i=0;i<len2;i++)
	{
		q[i]=d.x[len2-i-1];
	}
	
	if(len1>=len2)
	{
	max=len1;
		for(i=len2;i<len1;i++)
		{
		q[i]=0;
		}
	}
	else
	{
	max=len2;
		for(i=len1;i<len2;i++)
		{
		p[i]=0;
		}
	}
	
	int result[max];
	for(i=0;i<max;i++)
	{
		if(borrow==1)
			p[i]=p[i]-1;
		if(p[i]<q[i])
		{
			p[i]=p[i]+10;
			borrow=1;
		}
		else borrow=0;
		result[i]=p[i]-q[i];	
	}
	for(i=0;i<max;i++)
	{
		r.x[i]=result[max-i-1];
	}
	r.length=max;
	r.flag=1;
	return removeZeros(r);
	}
	
	
	else
	{
	r=getSubtraction(d,c);
	r.flag=-1;
	return removeZeros(r);
	}
	}
	else if(c.flag==1 && d.flag==-1)
	{
	d.flag=1;
	r=getSum(c,d);
	r.flag=1;
	d.flag=-1;
	return removeZeros(r);
	}
	else if(c.flag==-1 && d.flag==1)
	{
	c.flag=1;
	r=getSum(c,d);
	r.flag=-1;
	c.flag=-1;
	return removeZeros(r);
	}
	else
	{
	c.flag=1;
	d.flag=1;
	r=getSubtraction(d,c);
	}
}

int simple_division(struct bigint c,struct bigint d,int flag)
{
	int i=0;
	if(flag==0) c.length=d.length;
	while(isGreater(c,d))
	{
	c=getSubtraction(c,d);
	//printf("inside the while loop of simple division, following c with length %d and d with length %d check\n",c.length,d.length);
	//arrayPrint(c);
	//arrayPrint(d);
	i++;
	}
	//printf("quo %d \n",i);
	return i;
}

struct bigint simple_remainder(struct bigint c,struct bigint d,int flag)
{
	if(flag==0) c.length=d.length;
	while(isGreater(c,d))
	{
	c=getSubtraction(c,d);
	}
	//printf("rem %d \n",c.x[0]);
	return c;
}

struct bigint shift_with_zeros(struct bigint c,int number_of_zeros,int flag)
{
	int len=c.length;
	
	// flag 0 for left shift and 1 for right shift

	if(flag==0) {// left shift by that many zeros
		c.length=len+number_of_zeros;
		c.lengthDec=1;
		c.frac[0]=0;
		int i=0;
		for(i=0;i<number_of_zeros;i++)
			{	
			c.x[i+len]=0;
			}
		}
	else if(flag==1) //right shift by that many zeros
	{
	if(number_of_zeros<len)
		{
		int i=0;
		for(i=0;i<number_of_zeros;i++)
			c.frac[i]=c.x[i+(len-number_of_zeros)];
		c.lengthDec=number_of_zeros;
		c.length=len-number_of_zeros;
		}
	else
		{
		len=c.length;		
		int i=0;
		int* r;
		r=(int*)calloc(1000,sizeof(int));
		for(i=0;i<number_of_zeros;i++)
			c.frac[i]=0;
		for(i=0;i<c.lengthDec;i++)
			r[i]=c.frac[i];
		for(i=0;i<c.length;i++)
			c.frac[i+number_of_zeros]=r[i];
		for(i=0;i<len;i++)
			c.frac[number_of_zeros-len+i]=c.x[i];
		c.length=1;
		c.x[0]=0;
		c.lengthDec=c.lengthDec+number_of_zeros;
		
		}
	}
	
	return c;
}

struct bigint getDivision(struct bigint c,struct bigint d)
{
int num_shift=10;
struct bigint quo;

c=removeZeros(c);
d=removeZeros(d);

if(d.length==1 && d.lengthDec==1 && d.x[0]==0 && d.frac[0]==0)
	{
	printf("Diverr\n");
	exit(1);
	}
else
	{
	
	if(c.flag==1 && d.flag==1)
	{

	
	int cInt=c.length;
int cDec=c.lengthDec;
int dInt=d.length;
int dDec=d.lengthDec;

int maxDec=0;
if(cDec>=dDec)
	maxDec=cDec;
else
	maxDec=dDec;

int m;
for(m=0;m<maxDec;m++)
{
if(m<cDec)
c.x[m+cInt]=c.frac[m];
else
c.x[m+cInt]=0;
}
c.frac[0]=0;
c.lengthDec=1;

for(m=0;m<maxDec;m++)
{
if(m<dDec)
d.x[m+dInt]=d.frac[m];
else
d.x[m+dInt]=0;
}
d.frac[0]=0;
d.lengthDec=1;

c.length=cInt+maxDec;
d.length=dInt+maxDec;

c=removeZeros(c);
d=removeZeros(d);

c=removeZeros(shift_with_zeros(c,num_shift,0)); //0 for left shift

	
	if(isGreater(d,c))
	{
	
	if(Greater(d,c)) {quo.x[0]=0; quo.length=1; }
	else {quo.x[0]=1;  quo.length=1; }  
	}
else
	{
	struct bigint temp;
	int factorPoint=0;
	int lenC=c.length;
	int lenD=d.length;
	quo.x[0]=simple_division(c,d,0); //simple_digit is an integer from 0 to 9
	temp=simple_remainder(c,d,0);
	factorPoint=temp.length;
	temp.length=lenD;
	temp=setRemainder(temp,factorPoint);
	//printf("temp %d %d \n",temp.length,temp.x[0]);
	factorPoint=temp.length+1;
	int i=1,k=lenD;
	quo.length=1;
	int g;	

	while(i<=(lenC-lenD))
		{
		
		k=lenD+i-1;
		g=temp.length;
		temp.length=g+1;
		temp.x[k]=c.x[k];
		//printf("below two will be divided \n");
		//arrayPrint(temp);
		//arrayPrint(d);
		quo.x[i]=simple_division(temp,d,1);
		//printf("quo[%d] %d\n",i,quo.x[i]);
		temp=simple_remainder(temp,d,1);
		//arrayPrint(temp);
		factorPoint=temp.length;
		temp.length=g;
		temp.length=temp.length+1;
		temp=setRemainder(temp,factorPoint);
		//arrayPrint(temp);
		i++;
		quo.length=i;
		
		//printf("WHYY %d %d %d %d \n",temp.x[0],temp.x[1],temp.x[2],temp.length);
		}
		//arrayPrint(quo);
	quo=shift_with_zeros(quo,num_shift,1); //1 for right shift
	//printf("afterrr\n");
	//arrayPrint(quo);
	}
	quo.flag=1;
	
	return removeZeros(quo);
	
	}
	else if(c.flag==-1 && d.flag==-1)
	{
	c.flag=1;
	d.flag=1;
	quo=getDivision(c,d);
	quo.flag=1;
	return quo;
	}
	else
	{
	int a=c.flag;
	int b=d.flag;
	c.flag=1;
	d.flag=1;
	quo=getDivision(c,d);
	quo.flag=-1;
	c.flag=a;
	d.flag=b;
	return (quo);
	}


	}
}

struct bigint setRemainder(struct bigint temp,int factorPoint)
{	
	int lenFinal=temp.length;
	int lenNow=factorPoint;
	int* p;
	p=(int*)calloc(1000,sizeof(int));
	
	int k=lenFinal-lenNow;
	
	int i;
	for(i=0;i<k;i++)
	{
	p[0]=0;
	}
	for(i=k;i<lenFinal;i++)
	{
	p[i]=temp.x[i-k];
	}

	for(i=0;i<lenFinal;i++)
	{
	temp.x[i]=p[i];
	}
	temp.length=lenFinal;
	return temp;
}


struct bigint getMultiplication(struct bigint c, struct bigint d)
{
    c=removeZeros(c);
    d=removeZeros(d);
    int* a=(int*) calloc(1000,sizeof(int));
    int* b=(int*) calloc(1000,sizeof(int));
    int i;
    for(i=0;i<c.length;i++)
    {
        a[i]=c.x[i];
    }
    
    for(i=0;i<c.lengthDec;i++)
    {
        a[c.length+i]=c.frac[i];
    }
    
    for(i=0;i<d.length;i++)
    {
        b[i]=d.x[i];
    }
    
    for(i=0;i<d.lengthDec;i++)
    {
        b[d.length+i]=d.frac[i];
    }
    
    int len1=c.length+c.lengthDec;
    int len2=d.length+d.lengthDec;
    int j,k,l;
    int temp[1000];
    int temp2[100];
    int count=0;
    int carry;
    struct bigint result;
    struct bigint tempStruct;
    struct bigint tempresult;
    result.lengthDec=1;
    result.length=1;
    result.frac[0]=0;
    result.x[0]=0;
    result.flag=1;
    result.lengthDec=0;
    tempStruct.flag=1;
    tempresult.flag=1;
    tempStruct.lengthDec=1;
    tempresult.lengthDec=1;
    tempresult.frac[0]=0;
    tempStruct.frac[0]=0;
    for(i=len2-1;i>=0;i--)
    {
        carry=0;
        for(j=len1-1;j>=0;j--)
        {
            temp[len1-j-1]=((b[i]*a[j])+carry)%10;
            carry=((a[j]*b[i])+carry)/10;
        }
        if(carry!=0) { temp[len1]=carry; k=len1+1;}
        else { k=len1;}
        //reverse temp and add appropriate 0s
        for(l=0;l<k;l++)
        {
            temp2[l]=temp[k-l-1];
        }
        for(l=k;l<k+count;l++)
        {
            temp2[k]=0;
        }
        k=k+count;
        tempStruct.length=k;
        for(l=0;l<k;l++)
        {
            tempStruct.x[l]=temp2[l];
        }
        tempresult=getSum(result,tempStruct);
        result=tempresult;
        count++;
    }
    int decimalPos=c.lengthDec+d.lengthDec;
    k=result.length-decimalPos;
    struct bigint final;
    final.length=k;
    for(i=0;i<k;i++)
    {
        final.x[i]=result.x[i];
    }    
    final.lengthDec=decimalPos;
    for(i=0;i<decimalPos;i++)
    {
        final.frac[i]=result.x[k+i];
    }
    if(c.flag==d.flag) final.flag=1;
    else final.flag=-1;
    final=removeZeros(final);
    return final;
    
}

struct bigint getSum(struct bigint c,struct bigint d)
{
	c=removeZeros(c);
	d=removeZeros(d);
	struct bigint r;
	if(c.flag==d.flag)
	{
	r.flag=c.flag;
	int count1=c.length;
	int count2=d.length;
	int *a,*b;
	a = (int*) calloc(1000, sizeof(int));
	b = (int*) calloc(1000, sizeof(int));
	int i;
		for(i=0;i<count1;i++)
		{
		a[count1-1-i]=c.x[i];
		}

	for(i=0;i<count2;i++)
	{
	b[count2-1-i]=d.x[i];
	}
		
	int max=0,carry=0;
	
	if(count1>=count2)
	{
		max=count1;
		for(i=count2;i<count1;i++)
		{
			b[i]=0;
		}
	}
	else
	{
		max=count2;
		for(i=count1;i<count2;i++)
		{
			a[i]=0;
		}
	}

	int countDec1=c.lengthDec;
	int countDec2=d.lengthDec;
	int *u,*v,*y,*w;
	u = (int*) calloc(1000, sizeof(int));
	v = (int*) calloc(1000, sizeof(int));
	y = (int*) calloc(1000, sizeof(int));
	w = (int*) calloc(1000, sizeof(int));
	int maxDec=0;

	for(i=0;i<countDec1;i++)
	{
	y[i]=c.frac[i];
	}

	for(i=0;i<countDec2;i++)
	{
	w[i]=d.frac[i];
	}

	if(countDec1>=countDec2)
	{
		maxDec=countDec1;
		for(i=countDec2;i<countDec1;i++)
		{
			w[i]=0;
		}
	}
	else
	{
		maxDec=countDec2;
		for(i=countDec1;i<countDec2;i++)
		{
			y[i]=0;
		}
	}
	
	//reversing the lists
	for(i=0;i<maxDec;i++)
	{
	u[maxDec-1-i]=y[i];
	v[maxDec-1-i]=w[i];
	}
	
	int g[maxDec];
	for(i=0;i<maxDec;i++)
	{
		g[i]=((u[i]+v[i]+carry)%10);
		carry=((u[i]+v[i]+carry)/10);
	}
	r.lengthDec=maxDec;

	//saving the fractional part
	for(i=0;i<r.lengthDec;i++)
	{
	r.frac[i]=g[r.lengthDec-i-1];
	}
	
	//carry will be passed to the integer part

	int p[max+1];
	for(i=0;i<max;i++)
	{
		p[i]=((a[i]+b[i]+carry)%10);
		carry=((a[i]+b[i]+carry)/10);
	}
	r.length=max;
	if(carry!=0)
	{
		p[max]=1;
		r.length=max+1;
	}

	for(i=0;i<r.length;i++)
		{
		r.x[i]=p[r.length-i-1];
		}
	return removeZeros(r);
	}

	else if(c.flag==1 && d.flag==-1)
	{
	c.flag=1;
	d.flag=1;
	if(isGreater(c,d))               //isGreater() checks for greater than or equal to condition
	{
	r=getSubtraction(c,d);
	r.flag=1;
	c.flag=1;
	d.flag=-1;
	return removeZeros(r);}
	else
	{
	r=getSubtraction(d,c);
	r.flag=-1;
	c.flag=1;
	d.flag=-1;
	return removeZeros(r);}
	}

	else
	{
	c.flag=1;
	d.flag=1;
	if(isGreater(c,d))               //isGreater() checks for greater than or equal to condition
	{
	r=getSubtraction(c,d);
	r.flag=-1;
	c.flag=-1;
	d.flag=1;
	return removeZeros(r);}
	else
	{
	r=getSubtraction(d,c);
	r.flag=1;
	c.flag=-1;
	d.flag=1;
	return removeZeros(r);}
	}
}

void treeFree(struct ast *a)
{
switch(a->nodeType) {

/* two subtrees */
case PLUS:
case MINUS:
case MULTIPLY:
case DIVIDE:
case POWER:
treeFree(a->r);

/* one subtree */
case '|':
case UMINUS:
case SQT:
case LOG_10:
treeFree(a->l);

/* no subtree */
case 'K':
free(a);
break;

default: printf("internal error: free bad node %c\n", a->nodeType);
}
}
	
void yyerror(char *s) {
  printf("%s\n", s);
}


void main()
{
	yyparse();
}

void arrayPrint(struct bigint a)
{
if(a.length==0){
a.length=1;
a.x[0]=0;}
int i=0;
if(a.flag==-1)
{
printf("- ");
}
int len=a.length;
for(i=0;i<len;i++)
	printf("%d",a.x[i]);

int lenD=a.lengthDec;
if(lenD==1 && a.frac[0]==0)
	printf("\n");
else
	{
	if(lenD>0) 
		printf(".");

	for(i=0;i<lenD;i++)
		printf("%d",a.frac[i]);
	
	printf("\n");
	}
}
