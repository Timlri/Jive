library(RCurl)
library(jsonlite)
library(XML)
library(httr)

options(stringsAsFactors = FALSE)

# Set SSL certs globally
options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", 
                                                 package = "RCurl")))

clientId     <- readLines("~/Spectrum-R/EOS-EOL/clientId.txt")
clientSecret <- readLines("~/Spectrum-R/EOS-EOL/clientSecret.txt")

url1         <- "https://api.jivesoftware.com/analytics/v1/"
url2         <- "https://api.jivesoftware.com/analytics/v2/"

### Specify Curl options. See http://curl.haxx.se/docs/manpage.html
### -H -> header
### -v -> verbose
### -n -> netrc
opts         <- curlOptions(header = FALSE, verbose=TRUE, netrc = TRUE)
#                    userpwd = "username:password", netrc = FALSE)

### First, get authorization header by passing clientId/clientSecret
cmd1 <- "auth/login?" 
auth <- postForm(paste(url1,cmd1,clientId,"&",clientSecret,sep=""))

### Use date range of last 7 days
after  <- paste("after=",as.Date(Sys.Date()) - 2,"T00:00:00-0400&",sep="")

### look for recent popular unanswered questions
filt1   <- paste("filter=match(resolved,false)&",           # unanswered
                  "activity(view)&",                        # views
                  "type(thread)&",                          # from a thread
                  "match(isQuestion,true)&",                # its a question
                  after,
                  "count=all",sep="")                       # get all of them

url1  <- "https://api.jivesoftware.com/analytics/v2/export/activity/?"
req   <- GET(paste(url1,filt1,sep=""), 
             config(httpheader=c("Authorization"= auth[1]))) # get the url
json  <- content(req, as = "text")                           # parse
act   <- fromJSON(json)                                      # convert from JSON

#############################################################
#
# Description of act.list
#
#$ :List of 12
#..$ name            : chr "ACTIVITY_RESOLVED_QUESTION"
#..$ timestamp       : num 1.43e+12
#..$ context         : List of 1
#..$ payload         : Named list()
#..$ actorID         : int 10967201
#..$ actorType       : int 3
#..$ activityType    : chr "Resolved"
#..$ actionObjectId  : int 115657926
#..$ actionObjectType: int 27
#..$ containerId     : int 2280
#..$ containerType   : int 14
#..$ activity        : List of 5
#############################################################

activityName  <- act$list$name
timestamps    <- act$list$timestamp
datetime      <- as.POSIXct(timestamps/1000, origin="1970-01-01")
actorIDs      <- act$list$actorID
actionObjId   <- act$list$actionObjectId
containerId   <- act$list$containerId
username      <- act$list$activity$actor$username
email         <- act$list$activity$actor$email
actorType     <- act$list$actorType
objectType    <- act$list$activity$actionObject$objectType
open          <- act$list$activity$actionObject$open
objectId      <- act$list$activity$actionObject$objectId
status        <- act$list$activity$actionObject$status  
activityType  <- act$list$activityType
containerType <- act$list$containerType
name          <- act$list$activity$destination$name

df <- data.frame(activityName,timestamps,datetime,actorIDs,actionObjId,
                 containerId,username,email,actorType,
                 objectType,open,objectId,status,
                 activityType,containerType,name)

### Remove Expert Forums
df <- df[substr(df$name,nchar(df$name)-2,nchar(df$name)) != " EF", ]

write.csv(df,"Unresolved Questions.csv")

### now look at views
filt2 <- paste("filter=name(activity_view_thread)&",         # get views
                 after,
                 "count=all",sep="")                         # get all of them

req  <- GET(paste(url1,filt2,sep=""), 
             config(httpheader=c("Authorization"= auth[1]))) # get the url
json  <- content(req, as = "text")                           # parse
act   <- fromJSON(json)                                      # convert from JSON

activityName <- act$list$name
actorIDs      <- act$list$actorID
actionObjId   <- act$list$actionObjectId
objectType    <- act$list$activity$actionObject$objectType
objectId      <- act$list$activity$actionObject$objectId

name          <- act$list$activity$destination$name

df <- data.frame(activityName,actorIDs,actionObjId,
                 objectType,objectId,name)

### Remove Expert Forums
df <- df[substr(df$name,nchar(df$name)-2,nchar(df$name)) != " EF", ]

write.csv(df,"Views.csv")

### Finally, look at Likes, Comments, etc. to measure popularity
filt3 <- paste("filter=name(activity_like_thread)&",         # get views
               "activity_like_comment",
               "activity_update_question",
               "activity_update_message)",
               after,
               "count=all",sep="")                         # get all of them

req  <- GET(paste(url1,filt3,sep=""), 
            config(httpheader=c("Authorization"= auth[1]))) # get the url
json  <- content(req, as = "text")                           # parse
act   <- fromJSON(json)                                      # convert from JSON

activityName <- act$list$name
actionObjId   <- act$list$actionObjectId
objectType    <- act$list$activity$actionObject$objectType
objectId      <- act$list$activity$actionObject$objectId
name          <- act$list$activity$destination$name

df <- data.frame(activityName,actionObjId,
                 objectType,objectId,name)

# Remove Expert Forums
df <- df[substr(df$name,nchar(df$name)-2,nchar(df$name)) != " EF", ]

write.csv(df,"Likes.csv")