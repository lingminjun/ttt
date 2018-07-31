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
        
        return SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }()
    
    //同步请求
    public static func doRequest<T>(_ method: Alamofire.HTTPMethod, url: URLConvertible, parameters: Parameters? = nil) -> GeneralResponse<T> where T: HandyJSON {
        let semaphore = DispatchSemaphore(value: 0)
        let timeout = DispatchTime.init(uptimeNanoseconds: 60 * 1000 * 1000 * 1000 )
        
        var res:GeneralResponse<T>? = nil
        enRequest(method, url: url, parameters: parameters, queue: nil) { (resp:GeneralResponse<T>) in
            res = resp
            semaphore.signal()
        }
        
        let r = semaphore.wait(timeout: timeout) //永不超时
        if r == .timedOut {
            let resp = GeneralResponse<T>()
            resp.AppCode = "-100"
            resp.Message = "Time Out"
            return resp
        }
        
        //返回当前数据
        if let res = res {
            return res
        } else {
            let resp = GeneralResponse<T>()
            resp.AppCode = "-100"
            resp.Message = "Unknwon Error"
            return resp
        }
    }
    
    //异步请求
    public static func enRequest<T>(_ method: Alamofire.HTTPMethod, url: URLConvertible, parameters: Parameters? = nil, queue: DispatchQueue? = DispatchQueue.main, completion: @escaping (GeneralResponse<T>) -> Void) where T: HandyJSON {
        
        var encoding: ParameterEncoding = URLEncoding.default
        if method == .post {
            encoding = JSONEncoding.default
        }
        
        //构建请求
        let request = networkManager.request(url, method: method, parameters: parameters, encoding: encoding)
        
        //请求值，回调不在主线程
        request.validate().responseJSON(queue: nil,completionHandler: { (response) in
            var res:GeneralResponse<T>? = nil
            
            //序列化线程
            switch response.result {
            case .success(let JSON):
                //字符串数组返回值
                if let JSONArray = JSON as? [String], T.self == String.self {
                    let resp = GeneralResponse<T>()
                    resp.Results = JSONArray as? [T]
                    res = resp
                } else if let JSONArray = JSON as? [[String: Any]] {//返回值是array，则以array返回
                    let ary = [T].deserialize(from: JSONArray)
                    var lit:[T] = []
                    if let ary = ary {//类型转换
                        for ele in ary {
                            if let ele = ele {
                                lit.append(ele)
                            }
                        }
                    }
                    let resp = GeneralResponse<T>()
                    resp.Results = lit
                    res = resp
                } else if let JSONObject = JSON as? [String: Any] {
                    let obj = T.deserialize(from: JSONObject)
                    let resp = GeneralResponse<T>()
                    resp.Result = obj
                    res = resp
                } else {//无法解析数据
                    let resp = GeneralResponse<T>()
                    resp.AppCode = "-100"
                    resp.Message = "Data deserialization failed"
                    res = resp
                }
                
                break
            case .failure(let error)://因为Alamofire返回success必须是http返回200,这边并不标准，返回其他错误码时，同时还有body
                //构建新的错误，将AppCode带回去
                if let validData = response.data, validData.count > 0,
                    let json = try? JSONSerialization.jsonObject(with: validData) as? [String: Any],
                    let resp = GeneralResponse<T>.deserialize(from: json) {
                    res = resp
                } else {
                    let resp = GeneralResponse<T>()
                    resp.AppCode = "-100"
                    resp.Message = error.localizedDescription
                    resp.Details = error.localizedDescription
                    res = resp
                }
                
                break
            }
            
            //返回结果回调
            let block:() -> Swift.Void = {
                if let res = res {
                    completion(res)
                } else {
                    let resp = GeneralResponse<T>()
                    resp.AppCode = "-100"
                    resp.Message = "Unknwon Error"
                    completion(resp)
                }
            }
            
            if let queue = queue {
                queue.async(execute: block)
            } else {
                block()
            }
        })
    }
}

extension HTTPAccesser {
    //简单的get请求
    public static func get<T>(_ url: URLConvertible, parameters: Parameters? = nil) -> GeneralResponse<T>? where T: HandyJSON {
        return doRequest(.get, url: url, parameters: parameters)
    }
    
    //简单的get请求
    public static func post<T>(_ url: URLConvertible, parameters: Parameters? = nil) -> GeneralResponse<T>? where T: HandyJSON {
        return doRequest(.post, url: url, parameters: parameters)
    }
    
    //简单的get请求
    public static func get<T>(_ url: URLConvertible, parameters: Parameters? = nil, completion: @escaping (GeneralResponse<T>) -> Void) -> Void where T: HandyJSON {
        return enRequest(.get, url: url, parameters: parameters, completion: completion)
    }
    
    //简单的get请求
    public static func post<T>(_ url: URLConvertible, parameters: Parameters? = nil, completion: @escaping (GeneralResponse<T>) -> Void) -> Void where T: HandyJSON {
        return enRequest(.post, url: url, parameters: parameters, completion: completion)
    }
}

//特殊的返回值,支持字符数组
extension String : HandyJSON {
}

//接口响应
public class GeneralResponse<T:HandyJSON>: HandyJSON {
    
    //服务端错误情况返回结果集
    fileprivate var AppCode: String? = nil
    fileprivate var Message: String? = nil
    fileprivate var Details: String? = nil
    
    //结果集处理
    fileprivate var Result:T? = nil
    fileprivate var Results:[T]? = nil
    
    public var appCode:String {
        if let AppCode = AppCode {
            return AppCode
        }
        return ""
    }
    
    public var message:String {
        if let Message = Message {
            return Message
        }
        return ""
    }
    
    public var details:String {
        if let Details = Details {
            return Details
        }
        return ""
    }
    
    public var result:T? {
        if let Result = Result {
            return Result
        }
        return nil
    }
    
    public var results:[T] {
        if let Results = Results {
            return Results
        } else if let Result = Result {
            return [Result]
        }
        return []
    }
    
    public var success:Bool {
        if Results != nil || Result != nil {
            return true
        }
        return false
    }
    
    required public init() {
    }
    
}
