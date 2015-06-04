library(RCurl)
library(jsonlite)
library(XML)

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

### Get authorization header
cmd1 <- "auth/login?" 
auth <- postForm(paste(url1,cmd1,clientId,"&",clientSecret,sep=""))

headers <- list('Authorization' = auth[1])

### Get a list of activity in lastday
cmd2 <- "export/activity/lastday"
g2   <- getForm(paste(url2,cmd2,sep=""), .opts=list(httpheader=headers))

###  Get
opts <- curlOptions(header = FALSE, verbose=TRUE, netrc = TRUE, include = TRUE)
cmd3 <- "export/activity/csv/place?count=20"
g3   <- getForm(paste(url1,cmd3,sep=""), .opts=list(httpheader=headers))

url <- paste(url1,cmd3,sep="")
g6   <- fromJSON(txt=url)

### How many users logged in during the last hour
cmd4 <- "export/activity/lasthour?filter=action(Login)"
g4   <- getForm(paste(url2,cmd4,sep=""), .opts=list(httpheader=headers))

### Get latest create events
cmd5 <- "export/activity/lastday?filter=action(Create)"
g5   <- getForm(paste(url2,cmd5,sep=""), .opts=list(httpheader=headers))

### read jive activity
url  <- "https://api.jivesoftware.com/analytics/v2/export/activity/lastday"
req  <- GET(url, config(httpheader = c("Authorization" = auth[1])))
json <- content(req, as = "text")
act  <- fromJSON(json)
x <- act$list




  






