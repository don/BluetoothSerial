const fs = require('fs');
const path = require('path');
const xml2js = require('xml2js');

const PLUGIN_ID = "cordova-plugin-bluetooth-serial";
const androidPlatformRoot = "./platforms/android/";

let  deferral;

function removeKotlinSourceFiles(){

    const pluginXML = fs.readFileSync('./plugins/'+PLUGIN_ID+'/plugin.xml').toString();
    const parser = new xml2js.Parser();
    parser.parseString(pluginXML, (error, config) => {
        if (error) return;
        if (!config.plugin.hasOwnProperty('platform')) return;
        for (let platform of config.plugin.platform)
            if (platform['$'].name === 'android') {
                if (platform.hasOwnProperty('source-file')){
                    let sourceFiles = platform['source-file'];
                    for(let sourceFile of sourceFiles){
                        if (sourceFile['$'].hasOwnProperty('src')){
                            let src = sourceFile['$']['src'];
                            if(src.match(/\.kt/)){
                                let srcParts = src.split('/');
                                let filename = srcParts[srcParts.length - 1];
                                let filepath = sourceFile['$']['target-dir'];
                                filepath = androidPlatformRoot+filepath+'/'+filename;
                                if(fs.existsSync(path.resolve(filepath))){
                                    fs.unlinkSync(filepath);
                                    console.log("Removed Kotlin source file: "+filepath);
                                }
                            }
                        }
                    }
                }
                break;
            }
    });

}
module.exports = function(ctx) {
    try{
        deferral = ctx.requireCordovaModule('q').defer();
        removeKotlinSourceFiles();
        deferral.resolve();
    }catch(e){
        let msg = e.toString();
        console.dir(e);
        deferral.reject(msg);
        return deferral.promise;
    }
};
