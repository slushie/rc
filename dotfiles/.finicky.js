/**
* Save as ~/.finicky.js
*/
module.exports = {
    defaultBrowser: "Firefox",
    options: {
        hideIcon: true,
        urlShorteners: ["go", "go.netflix.com"]
    },
    handlers: [
        {
            match: finicky.matchHostnames(["meet.google.com"]),
            browser: "Google Chrome"
        }
    ]
};
