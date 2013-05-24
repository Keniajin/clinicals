/*created by kmwai from 19022013 til 21022013. this is aimed at visualization of core1 clinical data set 
----------------------------------------------------------------
creates a local variable called tod that is set to the date on the computer for today and then one called fname 
that has the stub named "malariaslides" in this case with the date appended */
  cd H:\stata_job\clinicalData\doFiles
	local time2=lower(word(c(current_time),1))
	local time=subinstr("`time2'", ":", "-",. )
	local tod=lower(word(c(current_date),1)+word(c(current_date),2)+word(c(current_date),3))
	local name = "core1visualization"+"`tod'"+"`time'"
	log using `name',text replace
	clear all
	set more off

	
*load the dataset
	odbc load, exec("select * from core1") dsn("prod") clear
	compress
	

*serialno
*extract the numeric part of the alphanumeric serial numbers
	egen nserial= sieve(serialno), char(0123456789)
	duplicates report nserial
*262 values with numserial as 0
	gen numserial= real(serialno)
* flag serials with alpha characters
	egen alphaserial= sieve(serialno), omit(0123456789)
	
		/*
	alphaserial |      Freq.     Percent        Cum.
	------------+-----------------------------------
			  A |        119       13.93       13.93
			  D |        263       30.80       44.73
			  K |        472       55.27      100.00
	------------+-----------------------------------
		  Total |        854      100.00
		*/

*dadm cleaning the date of admission (from \\dataserver\sharedata\Science\Statistics\coredata\do_files\JayBerkley\Core2_cleanup.do)
		//first,define the year of admission as your reference year:the long process is because the years are all in different formats. 
		gen year=real(substr( dadm ,-2,.))
		gen xyear=real(substr( dadm ,-3,.))
		gen yyear=real(substr( dadm ,1,4)) if xyear<89
		gen zyear=real(substr( dadm ,-4,.)) if xyear<89
		gen yr=max(yyear,year,zyear)		
		drop year xyear yyear zyear
		

		*identify the date formats across the years: results
		/*results: dd/mm/yyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	dd/mm/yyyy	dd/mm/yyyy	dd/mm/yyyy	dd/mm/yyyy 	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd yyyy-mm-dd
		for 			1989	1990			1991	1992			1993	1994			1995	1996			1997	1998			1999	2000			2001		2002		2003		2004	2005			2006		2007		2008		2009	2010		2011
		respectively.*/
		*split into year,month day in bits of 1989,1990-1997, 1998-2002, 2002-2011
		*1989, 1998-2002(dd/mm/yyyy)
		gen ndady=real(substr( dadm ,-4,.)) if (yr==89 | yr==98 | yr==99 | yr==2000 | yr==2001 | yr==2002)
		gen ndadm=real(substr( dadm ,4,2)) if (yr==89 | yr==98 | yr==99 | yr==2000 | yr==2001 | yr==2002)
		gen ndadd=real(substr( dadm ,1,2)) if (yr==89 | yr==98 | yr==99 | yr==2000 | yr==2001 | yr==2002)

		*1990-1997(ddmmyyyy)
		replace ndady=real(substr( dadm ,-2,.)) if yr>89 & yr<98
		replace ndadm=real(substr( dadm ,-4,2)) if yr>89 & yr<98
		replace ndadd=real(substr( dadm ,-6,2)) if yr>89 & yr<98

		*2002-2011(yyyy-mm-dd) - 
		*kmwai - changed to yr>=2002 from yr >2002 because of yr 2002 format
		replace ndady=real(substr( dadm ,1,4)) if yr>=2002 & yr<2012
		replace ndadm=real(substr( dadm ,6,2)) if yr>=2002 & yr<2012
		replace ndadd=real(substr( dadm ,-2,.)) if yr>=2002 & yr<2012

		*and now create the date of admission......
		replace ndady=ndady+1900 if ndady<1000
		gen ndad = mdy( ndadm , ndadd , ndady)
		format ndad %td
		*there are 3 outliers with the dadm as 300294 310697 720692

		replace ndad=mdy(06,22,1992) if trim(dadm)=="720692" & serialno=="9249"
		
		replace ndad=mdy(09,30,1997) if trim(dadm)=="300294" & serialno=="30204"
		replace yr=97 if trim(dadm)=="300294" & serialno=="30204"
		
		replace ndad=mdy(05,31,1997) if trim(dadm)=="310697" & serialno=="28289"
		
		*drop the ndady,ndadm,ndadd-they are no longer needed since we have a complete date- ndad
		*drop ndadd ndadm ndady
		*rename ndad ndadm

*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*dob
		*splitting the date of birth
		codebook dob
		* * br serialno ndad dob if !missing(dob)
		/*100% missing	100% missing	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	ddmmyyyy	dd/mm/yyyy	dd/mm/yyyy	dd/mm/yyyy	dd/mm/yyyy	dd/mm/yyyy	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd	yyyy-mm-dd
		for 1989	1990	1991	1992	1993	1994	1995	1996	1997	1998	1999	2000	2001	2002	2003	2004	2005	2006	2007	2008	2009	2010	2011
		respectively.*/
		*split into year,month day in bits of 1989-1997, 1998-2002, 2002-2011

		*1989-1997 (ddmmyy)

		gen ndoby=real(substr( dob ,-2,.)) if yr>88 & yr<98 
		gen ndobm=real(substr( dob ,3,2)) if yr>88 & yr<98
		gen ndobd=real(substr( dob ,1,2)) if yr>88 & yr<98		
		 

		*1998-2001,16Apr2002- 31Dec2002 (dd/mm/yyyy)
		replace ndoby=real(substr( dob ,-4,.)) if yr>97 & yr<2003
		replace ndobm=real(substr( dob ,4,2)) if yr>97 & yr<2003
		replace ndobd=real(substr( dob ,1,2)) if yr>97 & yr<2003

		*2002-2011 (yyyy-mm-dd)

		replace ndoby=real(substr( dob ,1,4)) if yr>=2002 & yr<2012
		replace ndobm=real(substr( dob ,6,2)) if yr>=2002 & yr<2012
		replace ndobd=real(substr( dob ,-2,.)) if yr>=2002 & yr<2012

		
		*and now create the date of birth......
		replace ndoby=ndoby+1900 if ndoby<1000
		gen ndob = mdy( ndobm , ndobd , ndoby)
		format ndob %td
		plot ndobm ndoby,encode  hlines(4) vlines(10)
		hist ndoby,  freq addlabels xlabel(1900(10)2012)  /*addplot(plot)  */
/*imputing dob
*code to identify what modification has been made to dob
notes: imputedob  coded as 0=complete date, 1= missing day, 2=missing day and month, 3=missing day,month & year, 4=incorrect date eg 30th Feb.
		gen imputedob=0 if ndob!=.
		replace imputedob=1 if ndobd==. & ndobm!=. & ndoby!=.
		replace imputedob=2 if ndobd!=. & ndobm==. & ndoby!=.
		replace imputedob=3 if ndobd==. & ndobm==. & ndoby!=.
		replace imputedob=4 if ndob==. & ndobd!=. & ndobm!=. & ndoby!=.
		replace imputedob=5 if ndobd==. & ndobm==. & ndoby==.
		
*generate the imputed dob
	replace ndobd=15 if imputedob==1
	replace ndobm=6 if imputedob==2
	replace ndobd=1 if imputedob==3
	replace ndobm=7 if imputedob==3

	gen ndobimpute= mdy(ndobm, ndobd, ndoby)
	format ndobimpute %td

*calculate age
	gen int(nagem)= (ndad-ndobimpute)/30.4375		
		
*-------------------------------------------
*/

/*Scatter for weight vs year of birth/year of admission
	*getting weight that is numeric only
	egen nweight3= sieve(weight), char(0123456789.)
*assumed that two decimal points was meant meant to be one. replace the two decimal points with one i.e 15..1 to 15.1
	replace nweight3 = subinstr(nweight3, "..", ".",.)
	*replace nweight3 = substr(nweight3, 1, 4) if substr(nweight3,-1,.) == "."
*removing the last decimal points ie 15. to 15 
	replace nweight3 = substr(nweight3, 1, length(nweight3) - 1) if substr(nweight3,-1,.) == "."
    gen nweight=real(nweight3)
	label drop nweight
	two scatter nweight ndoby, pstyle(p3) mlabel(ndoby)
	bro nweight weight if ndoby==1955*/

*SEx variable
* 278 values with missing sex values
*serial number 001511 with a sex value as 9
	tab sex
	gen nsex=2 if sex=="F" | sex=="f"
	replace nsex=1 if sex=="m" | sex=="M"
	codebook nsex
	label define nsex 1 M 2 F
	label values nsex nsex
	two scatter  ndoby nsex,pstyle(p3) mlabel(ndoby)
	two scatter  ndady nsex

*Scatter for age in months, datr of birth and date of adm
	*getting agemnths that is numeric only
	egen nagemonths= sieve(agemths), char(0123456789)
	destring nagemonths , replace
	histogram nagemonths
	two scatter nagemonths nweight if nweight<=100, pstyle(p1) mlabel(ndoby)
	local f0 = "red"
	local f1 = "green"
 twoway (scatter nagemonths nweight [fweight=N] if nsex==1, )mcolor(`f0')) ///
      (scatter nagemonths nweight [fweight=N] if nsex==2, ) mcolor(`f1')) ///
      , legend(off)
	  
	egen ntemp= sieve(temp), char(0123456789.)
*temp with (16808 missing values generated) some values with temp as DOA NA n availa NDone and NRecorded
	destring ntemp , replace
	histogram ntemp
	bro temp ntemp if ntemp>100
	two scatter  ntemp nagemonths, pstyle(p1) msymbol(Oh) mlabel(ndoby)
	plot ntemp nagemonths
		
