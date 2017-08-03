/*Another comment, just to create a new version*/
/*  MORE TEXT  */
/*Add the text between the SAS comments
to the metadata logconfig.xml file*/
/* New line of commenting */


/*
<!-- Audit.Data.Dataset.Open logger definition -->

<logger name="Audit.Data.Dataset.Open" additivity="false">
   <appender-ref ref="AuditLibraryFile"/>
   <level value="Trace"/>
</logger>

<!-- Audit.Data.Dataset.Delete logger definition -->

<logger name="Audit.Data.Dataset.Delete" additivity="false">
   <appender-ref ref="AuditLibraryFile"/>
   <level value="Trace"/>
</logger>

<!-- Audit.Data.Dataset.Rename logger definition -->

<logger name="Audit.Data.Dataset.Rename" additivity="false">
   <appender-ref ref="AuditLibraryFile"/>
   <level value="Trace"/>
</logger>


<!-- Audit.Data.Dataset File Appender Definition -->

<appender name="AuditLibraryFile" class="FileAppender">
   <param name="Append" value="true"/>
   <param name="ImmediateFlush" value="true"/>
   <param name="fileNamePattern" value=
               "SAS-configuration-directory/Lev1/
                SAS-application/server-name/Logs/
                Audit.Library_server_%d_%S{hostname}_%S{pid}.log"/>
   <layout>
      <param name="ConversionPattern" 
       value="DateTime=%d Userid=%u Action=%E{Audit.Dataset.Action} 
              Status=%E{Audit.Dataset.Status} Libref=%E{Audit.Dataset.Libref}
              Engine=%E{Audit.Dataset.Engine} Member=%E{Audit.Dataset.Member}
              NewMember=%E{Audit.Dataset.NewMember} MemberType=%E{Audit.Dataset.Memtype} 
              Openmode=%E{Audit.Dataset.Openmode} Path=%E{Audit.Dataset.Path} 
              Sysrc=%E{Audit.Dataset.Sysrc} Sysmsg=  %E{Audit.Dataset.Sysmsg}"
   </layout>
</appender>


*/



/* Specify the directory where your log files are saved. */

%let logdir=C:\audit\logs;

/* Specify a directory to save the audit data. */

libname audit "C:\audit\results";
 
/* Expand a passed in directory name and find all the filenames.  */

%macro findfiles(logdir);
   data filelist (keep=directory logfile hostname pid);
      format directory logfile $512. hostname $80. pid $8.;
      directory="&logdir.";
      rc=filename("ONE","&logdir.");
      if rc ne 0 then do;
         msgLine="NOTE: Unable to assign a filename to directory &logdir.";
         put msgLine;
         end;
        else do;
           did=dopen("ONE");
           if did > 0 then do;
              numfiles=dnum(did);
                  put numfiles=;
              do i=1 to numfiles;
                 logfile=dread(did,i);
                 hostname=scan(logfile,-3,'_.');
                 pid=scan(logfile,-2,'_.');
                 output;
               end;
           end;

          /* close the open filename and data set pointer */

          rc=filename("ONE");
          did=dclose(did);
      end;
   run;
%mend;
 
/* Read through a data set of directory name and filenames and read the audit logs.*/

%macro readfiles(list);
   %let dsid = %sysfunc(open(&list));
   %if &dsid %then %do;
      %syscall set(dsid);
      %let nobs =%sysfunc(attrn(&dsid,nlobs));
      %do i=1 %to &nobs;
         %let rc=%sysfunc(fetch(&dsid));
         %let ldir=%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,DIRECTORY))));
         %let lfile=%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,LOGFILE))));
         %let host=%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,HOSTNAME))));
       %let pid=%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,PID))));
         filename auditlog "&ldir.\&lfile."; 
       data auditlib;
       infile auditlog recfm=V lrecl=512 pad missover;
       informat DateTime B8601DT23.3; format   DateTime datetime23.3; 
       length Userid        $ 80;     label    Userid='Userid';
       length Action        $ 16;
       length Libref        $ 16;
       length Engine        $ 16;
       length Member        $ 32;
       length NewMember     $ 32;
       length MemberType    $ 16;
       length OpenMode      $ 16;
       length Path          $ 4096;
       length Hostname      $ 80;
       length Pid           $ 8;
       length Status        $ 16;
       length Sysrc           8;
       length Sysmsg        $ 512;
       input DateTime= Userid= Libref= Engine= Member= NewMember= MemberType= 
             OpenMode= Label= Path= Sysrc= Sysmsg=;
       
      /* Populate values that will come from log filename. */
 
       Hostname=trim("&Hostname."); 
           Pid=trim("&Pid.");
    run;
      
    proc append base=audit.file_opens data=auditlib; run; 
       %end;
    %let rc = %sysfunc(close(&dsid));
    %end;
 
%mend;
 
/* Look for files to process in a directory. */

%findfiles(&logdir);

/* Read the log files to produce a data set for reporting. */

%readfiles(filelist);
