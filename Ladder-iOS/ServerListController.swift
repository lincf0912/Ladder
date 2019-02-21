//
//  ServerListController.swift
//  Ladder-iOS
//
//  Created by TsanFeng Lam on 2019/2/20.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import UIKit
import QRCodeReader

struct NotificationKey {
    static let reloadServerDataNotif = "kReloadServerDataNotif"
}

class ServerListController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, QRCodeReaderViewControllerDelegate {
    // QRCodeReader&camera init
    lazy var reader: QRCodeReader = QRCodeReader()
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader                  = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton         = true
            $0.preferredStatusBarStyle = .lightContent
            
            $0.reader.stopScanningWhenCodeIsFound = false
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    let profileMgr = ServerProfileManager.instance
    var tableView : UITableView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        navigationItem.title = NSLocalizedString("Ladder", comment: "")
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Icons/QRCode"), style: .plain, target: self, action: #selector(openPost))
        let imageview = UIImageView(image: #imageLiteral(resourceName: "Icons/QRCode"))
        imageview.isUserInteractionEnabled = true
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(openPost(_:)))
        imageview.addGestureRecognizer(tapGes)
        let lognPressGes = UILongPressGestureRecognizer(target: self, action: #selector(openPost(_:)))
        imageview.addGestureRecognizer(lognPressGes)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageview)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = UIColor(red: 80 / 255, green: 140 / 255, blue: 240 / 255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        if let t = tableView {
            t.backgroundColor = UIColor.white;
            self.view.addSubview(t)
            t.dataSource = self
            t.delegate = self
            t.tableFooterView = UIView()
        }
        
        let notifyCenter = NotificationCenter.default
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NotificationKey.reloadServerDataNotif), object: nil, queue: nil) { (note) in
            self.tableView?.reloadData()
        }
    }
    
    // 移除通知<通知移除是在发通知控制器中移除>
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //处理扫描结果
    func handleQRCodeResult(_ result: String) {
        print("Completion with result: \(result)")
        if let url = NSURL(string: result), let profile = ServerProfile(url: url as URL) {
            let configVC = ConfigViewController(profile: profile)
            if let t = tableView {
                t.beginUpdates()
                self.profileMgr.profiles.append(profile)
                self.profileMgr.save()
                t.insertRows(at: [IndexPath(row: self.profileMgr.profiles.count-1, section: 0)], with: .automatic)
                t.endUpdates()
            }
            self.navigationController?.pushViewController(configVC, animated: true)
        } else {
            let alert = UIAlertController(
                title: "QRCodeReader",
                message: String ("result is error."),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @objc func openPost(_ ges : UIGestureRecognizer) {
        
        if ges.isKind(of: UITapGestureRecognizer.classForCoder()) {
            guard checkScanPermissions() else { return }
            
            readerVC.modalPresentationStyle = .formSheet
            readerVC.delegate               = self
            
            present(readerVC, animated: true, completion: nil)
        } else if ges.isKind(of: UILongPressGestureRecognizer.classForCoder()) {
            self.openLocalPhotoAlbum()
        }
    }
    
    //进入相册
    func openLocalPhotoAlbum() {
        let picker = UIImagePickerController()
        
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        picker.delegate = self;
        
        present(picker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        let image:UIImage? = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
        var QRCodeResult:String?
        
        //识别二维码
        if image != nil {
            let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
            let img = CIImage(cgImage: (image?.cgImage)!)
            
            let features : [CIFeature]? = detector.features(in: img, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
            
            if let _features = features {
                
                for feature in _features {
                    if feature.isKind(of: CIQRCodeFeature.self)
                    {
                        let featureTmp:CIQRCodeFeature = feature as! CIQRCodeFeature
                        
                        if let result = featureTmp.messageString {
                            if result.hasPrefix("ss://") {
                                QRCodeResult = result
                                break;
                            }
                        }
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: { [weak self] in
            if let _QRCodeResult = QRCodeResult {
                self?.handleQRCodeResult(_QRCodeResult)
            } else {
                let alert = UIAlertController(
                    title: "QRCodeReader",
                    message: String ("QRCode is wrong."),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self?.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true) { [weak self] in
            if (result.value.hasPrefix("ss://")) {
                self?.handleQRCodeResult(result.value)
            } else {
                let alert = UIAlertController(
                    title: "QRCodeReader",
                    message: String ("QRCode is wrong."),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    // 检测相机权限
    private func checkScanPermissions() -> Bool {
        do {
            return try QRCodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.openURL(settingsURL)
                        }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            default:
                alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            }
            
            present(alert, animated: true, completion: nil)
            
            return false
        }
    }
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}

extension ServerListController : UITableViewDataSource, UITableViewDelegate {
    //MARK: UITableViewDataSource
    
    // cell的个数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.profileMgr.profiles.count
    }
    // UITableViewCell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellid = "ServerCellID"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellid)
        if cell==nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellid)
            cell?.imageView?.contentMode = .scaleAspectFit
            cell?.accessoryType = .disclosureIndicator
        }
        let profile = self.profileMgr.profiles[indexPath.row]
        cell?.textLabel?.text = profile.title()
        if profile.uuid == self.profileMgr.activeProfileId {
            cell?.imageView?.image = #imageLiteral(resourceName: "Icons/selected")
        } else {
            cell?.imageView?.image = #imageLiteral(resourceName: "Icons/noselected")
        }
        return cell!
    }
    
    //MARK: UITableViewDelegate
    // 设置cell高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    // 选中cell后执行此方法
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
        let profile = self.profileMgr.profiles[indexPath.row]
        let configVC = ConfigViewController(profile: profile)
        self.navigationController?.pushViewController(configVC, animated: true)
    }
    //返回编辑类型，滑动删除
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    //在这里修改删除按钮的文字
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Delete", comment: "")
    }
    //点击删除按钮的响应方法，在这里处理删除的逻辑
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let profile = self.profileMgr.profiles[indexPath.row]
            tableView.beginUpdates()
            if self.profileMgr.activeProfileId == profile.uuid {
                self.profileMgr.setActiveProfiledId("")
            }
            self.profileMgr.profiles.remove(at: indexPath.row)
            //            self.profileMgr.save()
            tableView .deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}
