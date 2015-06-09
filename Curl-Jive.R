library(RCurl)
library(jsonlite)
library(XML)
library(httr)
library(data.table)

f6 = function(x) {
  ### count unique occurences within a numeric vector
  data.table(x)[, .N, keyby = x]
}

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

### Use date range of last 2 days
after  <- paste("after=",as.Date(Sys.Date()) - 2,"T00:00:00-0400&",sep="")

### look for recent popular unanswered questions
filt1   <- paste("filter=match(resolved,false)&",          # unanswered
                 "activity(view)&",                        # views
                 "type(thread)&",                          # from a thread
                 "match(isQuestion,true)&",                # its a question
                 after,
                 "count=all",sep="")                       # get all of them

req   <- GET(paste(url2,"export/activity/?",filt1,sep=""), 
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

dfq <- data.frame(activityName,timestamps,datetime,actorIDs,actionObjId,
                  containerId,username,email,actorType,
                  objectType,open,objectId,status,
                  activityType,containerType,name)

### Remove Expert Forums
dfq <- dfq[substr(dfq$name,nchar(dfq$name)-2,nchar(dfq$name)) != " EF", ]

### now look at views, likes, etc.
filt2 <- paste("filter=name(activity_view_thread,",          # get views
               "activity_like_thread,",                      # get likes
               "activity_follow_thread,",                    # follows
               "activity_aided_question,",
               "activity_rate_thread,",
               "activity_update_question)&",                 # get updates
               after,
               "count=all",sep="")                           # get all of them

req  <- GET(paste(url2,"export/activity/?",filt2,sep=""), 
            config(httpheader=c("Authorization"= auth[1])))  # get the url
json  <- content(req, as = "text")                           # parse
act   <- fromJSON(json)                                      # convert from JSON

v.activityName  <- act$list$name
v.actorIDs      <- act$list$actorID
v.timestamps    <- act$list$timestamp
v.datetime      <- as.POSIXct(v.timestamps/1000, origin="1970-01-01")
v.actionObjId   <- act$list$actionObjectId
v.objectType    <- act$list$activity$actionObject$objectType
v.objectId      <- act$list$activity$actionObject$objectId
v.name          <- act$list$activity$destination$name

dfv <- data.frame(v.activityName,v.actorIDs,v.datetime,v.actionObjId,
                  v.objectType,v.objectId,v.name)

### Remove Expert Forums
dfv <- dfv[substr(dfv$v.name,nchar(dfv$v.name)-2,nchar(dfv$v.name)) != " EF", ]

write.csv(dfv,"Views.csv")

### Update the unanswered questions with the counts of views, likes, etc.
dfq       <- dfq[order(dfq$actionObjId),]          
views     <- f6(v.actionObjId)
dfq$views <- (merge(dfq$actionObjId, views, by = 'x'))[,-1]

write.csv(dfq,"Unresolved Questions.csv")

