//
//  GifViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/6/16.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import ImageIO



class GifViewController: MMUIController {
    
    var web:UIWebView!
    var gif:UIImageView!//GifImageInfo
    var iio:UIImageView!//ImageIO
    var img:UIImageView!//播放NSData数据的GIF
    
    var gifImageInfo:GifImageInfo? = nil
    
    var flag:Int = 0
    
    //
    
    var data1:Data = Data()
    var data2:Data = Data()
    var data3:Data = Data()
    
    override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        view.backgroundColor = UIColor.white
        web = UIWebView(frame: CGRect(x: 10, y: 104, width: 150, height: 150))
        web.scalesPageToFit = true
        web.isOpaque = false
        gif = UIImageView(frame: CGRect(x: 10 + 150 + 10, y: 104, width: 150, height: 150))
        iio = UIImageView(frame: CGRect(x: 10, y: 104 + 150 + 10, width: 150, height: 150))
        img = UIImageView(frame: CGRect(x: 10 + 150 + 10, y: 104 + 150 + 10, width: 150, height: 150))
        self.view.addSubview(web)
        self.view.addSubview(gif)
        self.view.addSubview(iio)
        self.view.addSubview(img)
        return true
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        if let url = Bundle.main.url(forResource: "gif1", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            data1 = data
        }
        if let url = Bundle.main.url(forResource: "gif2", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            data2 = data
        }
        if let url = Bundle.main.url(forResource: "gif3", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            data3 = data
        }
        
        let sel = #selector(GifViewController.rightAction)
        //title: String?, style: UIBarButtonItemStyle, target: Any?, action: Selector?
        let item = UIBarButtonItem(title: "选项", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
        
        flag = 1
        webShowGif(data: data1)
        gifShowGif(data: data1)
        iioShowGif(data: data1)
    }
    
    func webShowGif(data:Data) {
        let now = Date().timeIntervalSince1970 * 1000
        web.load(data, mimeType: "image/gif", textEncodingName: "UTF-8", baseURL: URL(fileURLWithPath: ""))
        print("\((Date().timeIntervalSince1970 * 1000) - now))");
    }
    
    func gifShowGif(data:Data) {
        let now = Date().timeIntervalSince1970 * 1000
        if let info = NSData.gifInfo(withGIFData: data) {
            //        let advTimeGif = UIImage.gifImageWithData(data:data as! NSData)
            if let images = info.images as? [UIImage] {
                gif.image = UIImage.animatedImage(with: images, duration: info.duration)
            }
//            gif.animationImages = info.images as? [UIImage]
//            gif.animationDuration = info.duration
//            gif.startAnimating()
        }
        print("\((Date().timeIntervalSince1970 * 1000) - now))");
    }
    
    func iioShowGif(data:Data) {
        let now = Date().timeIntervalSince1970 * 1000
        let advTimeGif = UIImage.gifImageWithData(data:data as! NSData)
        iio.image = advTimeGif;
        print("\((Date().timeIntervalSince1970 * 1000) - now))");
    }
    
    @objc func rightAction() -> Void {
        
        flag = flag + 1
        
        let mode = 11
        
        if flag % mode == 0 {
            webShowGif(data: data3)
            gifShowGif(data: data3)
            iioShowGif(data: data3)
        } else if flag % mode == 1 {
            webShowGif(data: data1)
            gifShowGif(data: data1)
            iioShowGif(data: data1)
        } else if flag % mode == 2 {
            webShowGif(data: data2)
            gifShowGif(data: data2)
            iioShowGif(data: data2)
        }else if let url = Bundle.main.url(forResource: "gif0\((flag % mode - 2))", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            webShowGif(data: data)
            gifShowGif(data: data)
            iioShowGif(data: data)
        }
        
//        let sheet = UIActionSheet(title: "跳转", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: "百度")
//        sheet.addButton(withTitle: "测试")
//        sheet.addButton(withTitle: "测试1")
//        sheet.addButton(withTitle: "瀑布")
//        sheet.addButton(withTitle: "瀑布2")
//        sheet.addButton(withTitle: "一级")
//        sheet.addButton(withTitle: "二级")
//        sheet.show(in: self.view)
    }
}

extension UIImage {
    
    public class func gifImageWithData(data: NSData) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source: source)
    }
    
    public class func gifImageWithURL(gifUrl:String) -> UIImage? {
        guard let bundleURL = NSURL(string: gifUrl)
            else {
                print("image named \"\(gifUrl)\" doesn't exist")
                return nil
        }
        guard let imageData = NSData(contentsOf: bundleURL as URL) else {
            print("image named \"\(gifUrl)\" into NSData")
            return nil
        }
        
        return gifImageWithData(data: imageData)
    }
    
    public class func gifImageWithName(name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        
        guard let imageData = NSData(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(data: imageData)
    }
    
    class func delayForImageAtIndex(index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()), to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        print("frame delayl \(delay)");
        if delay < 0.01 {//兼容一些过老的gif
            delay = 0.10
        }
        print("frame delayx \(delay)");
        return delay
    }
    
    class func gcdForPair(a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a! < b! {
            let c = a!
            a = b!
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b!
                b = rest
            }
        }
    }
    
    class func gcdForArray(array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(a: val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(index: Int(i), source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(array: delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
        
        return animation
    }
}
