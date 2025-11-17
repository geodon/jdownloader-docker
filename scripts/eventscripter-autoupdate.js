/*
    Update when JD is Idle
    Trigger Required: "Interval" (Recommended: 600000 (10 mins.) or more)
*/

if (
    callAPI("update", "isUpdateAvailable") &&
    !callAPI("linkcrawler", "isCrawling") &&
    !callAPI("linkgrabberv2", "isCollecting") &&
    !callAPI("extraction", "getQueue").length &&
    isDownloadControllerIdle()
) {
    callAPI("update", "restartAndUpdate");
}
