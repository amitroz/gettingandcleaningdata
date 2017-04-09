# R script that downloads, cleans and summarizes human activity data from smartphones

download.data = function(){
    
    #checks that all relevant packages are available, otherwise installs them
    packages <- c("data.table","plyr","dplyr")
    sapply(packages, require, character.only = TRUE, quietly = TRUE)
    
    #sets the datapath that will be used throughout the script
    path <- getwd()
    dataPath <- file.path(path,"UCI HAR Dataset")
    
    url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
    
    zipname <- "data.zip"
    
    #downloads and unzips the data if the zip does not exist
    if(!file.exists(file.path(path,zipname)))
    {
        download.file(url, file.path(path, zipname))
        unzip(zipfile = file.path(path, zipname),overwrite = T)
    } 
    return(dataPath)
}

merge.data = function(dataPath){
    #reads X data and combines test and train
    X_train <- fread(file.path(dataPath,"train","X_train.txt"))
    X_test  <- fread(file.path(dataPath,"test","X_test.txt"))
    X_data <- rbind(X_train,X_test)
    
    #reads Y data and combines test and train
    Y_train <- fread(file.path(dataPath,"train","Y_train.txt"))
    Y_test  <- fread(file.path(dataPath,"test","Y_test.txt"))
    Y_data <- rbind(Y_train,Y_test)
    
    #gives the Y_data activity labels after merging with activity table
    activity_labels <- fread(file.path(dataPath,"activity_labels.txt"))
    Y_data <- merge(x=Y_data,y = activity_labels,by = "V1",all.x = T,sort = FALSE)
    Y_data$V1 <- NULL
    
    #reads subjects
    subjects_train <- fread(file.path(dataPath,"train","subject_train.txt"))
    subjects_test  <- fread(file.path(dataPath,"test" ,"subject_test.txt" ))    
    Subjects_data <- rbind(subjects_train,subjects_test)
    
    #renames data table columns for each data set
    features <- fread(file.path(dataPath,"features.txt"))
    names(Subjects_data) <- "subject"
    names(X_data) <- features$V2
    names(Y_data) <- "activityName"
    
    #appends all the data to 1 large data table
    cbind(Subjects_data,Y_data,X_data)
}

summarize.data = function(dt){
    #gets the column numbers of columns with mean or std
    mean_std_Cols <- grep("-mean\\(\\)|-std\\(\\)", names(dt))
    #extracts the relevant columns
    dt_ms <- dt[,c(1,2,mean_std_Cols),with=F]
    
    #performs mean on each column by the subject and activity
    tidy <- dt_ms[,lapply(.SD,mean),.SDcols=-c(1,2), by=c("subject","activityName")]
    
    return(tidy)
}


clean = function(){
    dataPath <- download.data()
    dt       <- merge.data(dataPath)
    tidy <- summarize.data(dt)
    
    write.csv(tidy, "UCI_HAR_tidy.csv", row.names=FALSE) 
}


