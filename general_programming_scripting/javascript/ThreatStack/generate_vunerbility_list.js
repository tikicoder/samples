
async function main(){

    if (!String.prototype.startsWith) {
        Object.defineProperty(String.prototype, 'startsWith', {
            value: function(search, rawPos) {
                var pos = rawPos > 0 ? rawPos|0 : 0;
                return this.substring(pos, pos + search.length) === search;
            }
        });
    }
    if (!String.prototype.endsWith) {
        String.prototype.endsWith = function(search, this_len) {
            if (this_len === undefined || this_len > this.length) {
            this_len = this.length;
            }
            return this.substring(this_len - search.length, this_len) === search;
        };
    }
    if (!String.prototype.includes) {
        String.prototype.includes = function(search, start) {
            'use strict';
        
            if (search instanceof RegExp) {
            throw TypeError('first argument must not be a RegExp');
            }
            if (start === undefined) { start = 0; }
            return this.indexOf(search, start) !== -1;
        };
    }
    if (!String.prototype.contains) {
        String.prototype.contains = String.prototype.includes;
    }
    
    let itemListClassName = "ItemList"
    let itemListDataClassName = "ItemList__list"
    let vulnerabilityTabClassName = "VulnsTab__body"
    let vulnerabilityTab = document.querySelectorAll("div."+vulnerabilityTabClassName)[0]
    

    let vulnerabilityTabItemLists = vulnerabilityTab.querySelectorAll("div."+itemListClassName)
    
    let completeOutput = ""
    for (let index = 0; index < vulnerabilityTabItemLists.length; index++){
        let outputData = vulnerabilityTabItemLists[index].getElementsByTagName("header")[0].innerText.split("\n")[0]
        outputData += "\n\n"
        
        let vulnerabilityData = vulnerabilityTabItemLists[index].querySelectorAll("ul."+itemListDataClassName+" > li")
        
        for (let indexData = 0; indexData < vulnerabilityData.length; indexData++){
            let itemName = vulnerabilityData[indexData].querySelectorAll("div.ListVulnOption__pkg")[0]
            let itemInfo = vulnerabilityData[indexData].querySelectorAll("div.ListVulnOption__cves")           
            let itemNotice = vulnerabilityData[indexData].querySelectorAll("div.ListVulnOption__notice")

            outputData += (itemName.getAttribute("title") + "\n")
            if (itemInfo.length > 0){
                itemInfo=itemInfo[0]
                outputData += (itemInfo.querySelectorAll("a")[0].innerText + "\n")
                outputData += (itemInfo.querySelectorAll("a")[0].getAttribute("href") + "\n")
            }
            
            if (itemNotice.length > 0){
                itemNotice=itemNotice[0]
                let noticeLink = itemNotice.querySelectorAll("a")
                if (itemNotice.length > 0){
                    noticeLink = noticeLink[0]
                    outputData += (noticeLink.innerText + "\n")
                    outputData += (noticeLink.getAttribute("href") + "\n")
                }
            }
            outputData += "\n"
        }
        completeOutput += (outputData + "\n\n\n\n")
        

    }
    console.log(completeOutput)

}


main()
