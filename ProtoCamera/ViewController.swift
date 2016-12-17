//
//  ViewController.swift
//  ProtoCamera
//
//  Created by Win Raguini on 11/26/16.
//  Copyright © 2016 Win Inc. All rights reserved.
//

import UIKit
import SCLAlertView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(type: .custom)
        button.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 26.0, height: 13.0))
        button.setTitleColor(.blue, for: .normal)
        button.setTitle("Start camera", for: .normal)
        button.addTarget(self, action: #selector(didPressButton(button:)), for: .touchUpInside)
        view.addSubview(button)
        button.autoCenterInSuperview()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    

}



extension ViewController {
    func didPressButton(button: UIButton) -> Void {
        if !UIImagePickerController.isCameraDeviceAvailable(.rear) {
            showCameraAlert()
        } else {
            let vc = CameraViewController()
            //The view model here should have the question and the user associated with it
            vc.viewModel = CameraViewModel()
            self.present(vc, animated: true, completion: nil)
        }
    }
}

func showCameraAlert() {
    let alertView = SCLAlertView()
    alertView.showTitle(
        "Cannot access camera.",
        subTitle: "You need access to a camera to record an answer.",
        duration: 0.0,
        completeText: "Okay",
        style: .info,
        colorStyle: 0xA429FF,
        colorTextButton: 0xFFFFFF
    )

}
