# Tar Shell script
Before running  make sure permission bits are set right. 
Running
```
	chmod a+rwx tar_rep.sh 
```
will do the job.

## Functionalities: 
This script performs only three types of operations, [c]reate, e[x]tract and lis[t] archives.

The general format of any command is as follows:
bash tar_rep.sh [mode] [verbose] -f [archive] [files]
where [mode] can be -c , -t , or -x
[verbose] -v is optional,
and at the end [files] are the list of files to be operated on.

	
Note: In all the commands that follows, verbose -v tag is optional.

## Creation:
for files f1.txt f2.txt f3.txt to be archived run:
```
bash tar_rep.sh -c -v -f arch.txt f1.txt f2.txt f3.txt
```
where arch.txt is the name of archive file thus created.

## Extraction:
Note: The script performs extraction all at once only.

Use the following command for extraction from an existing archive named arch.txt:
```
bash tar_rep.sh -x -v -f arch.txt
```

## Listing:
For listing all files use command:
```	
bash tar_rep.sh -t -v -f arch.txt  
```
For listing info of some specific files, say a.txt and b.txt:
```	
bash tar_rep.sh -t -v -f arch.txt a.txt b.txt
```	

Note:
- The script is designed for text files, so using it over media files like .mp4 might corrupt them.
- using combined tags like cvf, tf etc. is NOT supported by the script.So for cvf option, -c -v -f needs to be entered (full command is as specified above) and for tf -t -f needs to entered.
- Permutation of these tags doesn't affect the script as long as the archive name is next to -f tag. For example: the following command is valid:
```
        bash tar_rep.sh -f [archive] -v -x
```
but the below command is INVALID:
```
bash tar_rep.sh -f -v -x [archive]
```

