//
//  SwLoader.swift
//  HelloCordova
//
//  Created by Max Fisher on 6/28/21.
//

import Foundation
import WebKit

@objc class SwLoader: CDVPlugin {
    
    var stoppedTasks = NSMutableDictionary()
    
    override func pluginInitialize() {
        print("SwLoader plugin initialized")
    }
    
    @objc func overrideSchemeTask(_ urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let path = urlSchemeTask.request.url?.path else {
            return false
        }
        if !path.hasPrefix("/_cordova_proxy_/") {
            return false
        }
        let webViewTarget = path.replacingOccurrences(of: "/_cordova_proxy_/", with: "")
        let base = Bundle.main.bundleURL.appendingPathComponent("www")
        let deviceLocation = base.appendingPathComponent(webViewTarget)
        let task = URLSession.shared.dataTask(with: deviceLocation) { [self] (data,response,error) in
            if stoppedTasks[urlSchemeTask.hash] != nil {
                print("Url Scheme tasked stoped while request was in flight")
                stoppedTasks.removeObject(forKey: urlSchemeTask.hash)
            } else if error != nil {
                urlSchemeTask.didFailWithError(error!)
            } else {
                let headers = [
                    "Access-Control-Allow-Origin":"*",
                    "Cache-Control": "no-cache"
                ]
                let fake_url = URL(string: "http://cordova-proxy/".appending(webViewTarget))!
                let fake_res = HTTPURLResponse(url: fake_url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)
                urlSchemeTask.didReceive(fake_res!)
                urlSchemeTask.didReceive(data!)
                urlSchemeTask.didFinish()
            }
        }
        task.resume()
        return true
    }
    
    @objc func stopSchemeTask(_ urlSchemeTask:WKURLSchemeTask) {
        stoppedTasks[urlSchemeTask.hash] = urlSchemeTask
    }
    
    @objc func log(_ command:CDVInvokedUrlCommand) {
        print(command.arguments ?? "Could Not log arguments ")
    }
}
