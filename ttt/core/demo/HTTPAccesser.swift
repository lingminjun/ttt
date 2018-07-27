//
//  HTTPAccesser.swift
//  ttt
//
//  Created by lingminjun on 2018/7/19.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import Alamofire
import HandyJSON

public final class HTTPAccesser {
    static let networkManager: SessionManager = {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 60
        var serverTrustPolicies: [String: ServerTrustPolicy] = [:]
        
//        if Constants.Path.TrustAnyCert {
//            for domain in Constants.Path.ignoreSSLDomains {
//                serverTrustPolicies[domain] = .disableEvaluation
//            }
//        }
        
        return SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }()
    
    public static func request<Value: HandyJSON>(
        _ method: Alamofire.HTTPMethod,
        url: URLConvertible,
        parameters: Parameters? = nil,
        appendUserKey: Bool = true,
        appendUserId: Bool = true,
        userKey: String? = nil,
        shouldShowErrorDialog: Bool = true,
        success: ((_ value: Value) -> Void)? = nil,
        failure: ((_ error: Error) -> Bool)? = nil
        ) {
        
//        var factoryParameters: Parameters = ["cc" : Context.getCc() as Any]
//
//        switch method {
//        case .post :
//            factoryParameters["CultureCode"] = Context.getCc()
//            if appendUserId {
//                factoryParameters["UserId"] = Context.getUserId()
//            }
//            if appendUserKey {
//                factoryParameters["UserKey"] = Context.getUserKey()
//            }
//        case .get :
//            if appendUserKey {
//                factoryParameters["userkey"] = (userKey ?? Context.getUserKey())
//            }
//        default: break
//        }
        
//        if let para = parameters {
//            for (k, v) in para {
//                factoryParameters[k] = v
//            }
//        }
        
        var encoding: ParameterEncoding = URLEncoding.default
        if method == .post {
            encoding = JSONEncoding.default
        }
        
        let request = networkManager.request(url,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding)
        
        //请求值
        let queue = DispatchQueue.init(label: "temp")
        request.validate().responseJSON(queue: queue,completionHandler: { (response) in
            
        })
        
    }
}
