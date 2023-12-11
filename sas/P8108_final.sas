
ods pdf file="/home/u63390424/P8108/P8108_final_code.pdf" startpage=yes;
ods noproctitle;

proc import out=new datafile="/home/u63390424/P8108/brv.xlsx" 
	dbms=xlsx replace;
	getnames=yes; 
	run;


/* Split the data by bereavement status */
data new;
    set new;
    /* Convert character dates to SAS numeric dates */
    doe = input(doe, yymmdd10.);
    dob = input(dob, yymmdd10.);
    dox = input(dox, yymmdd10.);
    dosp = input(dosp, yymmdd10.);
    time=dox-doe;
    if (dosp < dox) then do;
        brv = 1;
        doe_tmp = doe;
        doe = dosp;
        output;
        brv = 0;
        doe = doe_tmp;
        dox = dosp;
        fail = 0;
        output;
    end;
    else do;
        brv = 0;
        output;
    end;
run;



proc phreg data=new;
     model time * fail(0) = sex disab health;
run;



/* Stratified Cox model (separate baseline for brv) */
proc phreg data=new;
    model time * fail(0) = sex disab health;
    strata brv;
run;


proc lifetest data= new outsurv=kml plots=s; time time * fail(0); strata brv;
run;

ods graphics on;
proc lifetest data=new method=KM plots=(survival logsurv h loglogs) outsurv=survival;
time time * fail(0); strata/group=brv; 
run;
ods graphics off;

data all;
set kml (in=a) pred1;
if a and sex=1 then ID="observed female"; if a and sex=2 then id = "observed male"; run; title2 'Observed vs Fitted';



proc phreg data = new;
class brv;
model time * fail(0) = sex disab health;
disablog = disab*log(time); 
healthlog = health*log(time);
run;


*** schoenfel residual;



proc phreg data=new;
class sex;
model time * fail(0) = sex disab health;
output out=resid wtressch=wschoebfeld1 wschoebfeld2 wschoebfeld3; 
run; 




proc sgplot data=resid;
yaxis grid;
refline 0/ axis=y;
scatter y=wschoebfeld2 x =time; run;


title2 "platelet";
proc sgplot data=resid;
yaxis grid;
refline 0 /axis=y;
scatter y=wschoebfeld3 x=time; run;

ods pdf close;